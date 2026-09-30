#include "nativechrome.h"

#include <QColor>
#include <QCoreApplication>
#include <QTranslator>
#include <QGuiApplication>
#include <QQmlEngine>
#include <QQuickImageProvider>
#include <QQuickWindow>

#import <AppKit/AppKit.h>

// Built without ARC, so ownership below is manual.

static NSToolbarItemIdentifier const kBackItem = @"com.moonlight-stream.back";
static NSToolbarItemIdentifier const kUpdateItem = @"com.moonlight-stream.update";
static NSToolbarItemIdentifier const kAddPcItem = @"com.moonlight-stream.addpc";
static NSToolbarItemIdentifier const kHelpItem = @"com.moonlight-stream.help";
static NSToolbarItemIdentifier const kSettingsItem = @"com.moonlight-stream.settings";

// The main window's saved size and position (NSWindow frame autosave)
static NSString* const kWindowFrameName = @"MoonlightMainWindow";

@interface MLToolbarController : NSObject <NSToolbarDelegate>
{
@public
    NativeChrome* chrome;
    NSToolbar* toolbar;
    NSMutableDictionary<NSToolbarItemIdentifier, NSToolbarItem*>* items;
}
- (void)refresh;
@end

@implementation MLToolbarController

- (instancetype)initWithChrome:(NativeChrome*)owner
{
    if ((self = [super init])) {
        chrome = owner;
        items = [[NSMutableDictionary alloc] init];

        [self addItem:kBackItem symbol:@"chevron.backward" label:@"Back" action:@selector(back:)];
        [self addItem:kUpdateItem symbol:@"arrow.down.circle" label:@"Update" action:@selector(update:)];
        [self addItem:kAddPcItem symbol:@"plus" label:@"Add Computer" action:@selector(addPc:)];
        [self addItem:kHelpItem symbol:@"questionmark.circle" label:@"Help" action:@selector(help:)];
        [self addItem:kSettingsItem symbol:@"gearshape" label:@"Settings" action:@selector(settings:)];

        // The back button leads, like Finder and Safari; everything else trails
        items[kBackItem].navigational = YES;

        toolbar = [[NSToolbar alloc] initWithIdentifier:@"com.moonlight-stream.main"];
        toolbar.delegate = self;
        toolbar.displayMode = NSToolbarDisplayModeIconOnly;
        toolbar.allowsUserCustomization = NO;
    }
    return self;
}

- (void)dealloc
{
    toolbar.delegate = nil;
    [toolbar release];
    [items release];
    [super dealloc];
}

- (void)addItem:(NSToolbarItemIdentifier)identifier symbol:(NSString*)symbol label:(NSString*)label action:(SEL)action
{
    NSToolbarItem* item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    item.image = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:label];
    item.label = label;
    item.paletteLabel = label;
    item.toolTip = label;
    item.target = self;
    item.action = action;
    item.bordered = YES;
    items[identifier] = item;
    [item release];
}

- (NSArray<NSToolbarItemIdentifier>*)toolbarDefaultItemIdentifiers:(NSToolbar*)bar
{
    return @[ kBackItem, NSToolbarFlexibleSpaceItemIdentifier, kUpdateItem, kAddPcItem, kHelpItem, kSettingsItem ];
}

- (NSArray<NSToolbarItemIdentifier>*)toolbarAllowedItemIdentifiers:(NSToolbar*)bar
{
    return [self toolbarDefaultItemIdentifiers:bar];
}

- (NSToolbarItem*)toolbar:(NSToolbar*)bar itemForItemIdentifier:(NSToolbarItemIdentifier)identifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return items[identifier];
}

- (void)setItem:(NSToolbarItemIdentifier)identifier visible:(BOOL)visible
{
    NSToolbarItem* item = items[identifier];
    // NSToolbarItem.hidden is macOS 15+; on older systems disable the item instead
    if (@available(macOS 15.0, *)) {
        item.hidden = !visible;
    }
    item.enabled = visible;
}

- (void)refresh
{
    [self setItem:kBackItem visible:chrome->canGoBack()];
    [self setItem:kAddPcItem visible:chrome->showAddPc()];
    [self setItem:kHelpItem visible:chrome->showHelp()];
    [self setItem:kSettingsItem visible:chrome->showSettings()];

    QString updateText = chrome->updateText();
    [self setItem:kUpdateItem visible:!updateText.isEmpty()];
    items[kUpdateItem].toolTip = updateText.toNSString();
}

- (void)back:(id)sender { emit chrome->backClicked(); }
- (void)update:(id)sender { emit chrome->updateClicked(); }
- (void)addPc:(id)sender { emit chrome->addPcClicked(); }
- (void)help:(id)sender { emit chrome->helpClicked(); }
- (void)settings:(id)sender { emit chrome->settingsClicked(); }

@end

// Renders "image://sfsymbol/<name>/<RRGGBB>" as the SF Symbol in that color, or
// "image://sfsymbol/<name>/multicolor" in the symbol's own colors (like the yellow alert triangle)
class SfSymbolImageProvider : public QQuickImageProvider
{
public:
    SfSymbolImageProvider() : QQuickImageProvider(QQuickImageProvider::Image) {}

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override
    {
        @autoreleasepool {
            int slash = id.lastIndexOf('/');
            QString name = slash > 0 ? id.left(slash) : id;
            QString colorSpec = slash > 0 ? id.mid(slash + 1) : QString();
            bool multicolor = colorSpec == QLatin1String("multicolor");
            QColor color = !colorSpec.isEmpty() && !multicolor ? QColor("#" + colorSpec) : QColor(Qt::white);

            // Render at 2x so it stays sharp on Retina displays
            int logical = qMax(16, requestedSize.isValid() ? qMax(requestedSize.width(), requestedSize.height()) : 64);
            int pixels = logical * 2;

            NSImage* symbol = [NSImage imageWithSystemSymbolName:name.toNSString() accessibilityDescription:nil];
            if (symbol == nil) {
                if (size) {
                    *size = QSize();
                }
                return QImage();
            }

            NSColor* tint = [NSColor colorWithSRGBRed:color.redF() green:color.greenF() blue:color.blueF() alpha:color.alphaF()];
            NSImageSymbolConfiguration* coloring = multicolor ? [NSImageSymbolConfiguration configurationPreferringMulticolor]
                                                              : [NSImageSymbolConfiguration configurationWithHierarchicalColor:tint];
            NSImageSymbolConfiguration* config =
                [[NSImageSymbolConfiguration configurationWithPointSize:pixels * 0.8 weight:NSFontWeightRegular]
                    configurationByApplyingConfiguration:coloring];
            symbol = [symbol imageWithSymbolConfiguration:config];

            // Fit the symbol into a square canvas, keeping its aspect ratio
            NSSize symbolSize = symbol.size;
            CGFloat scale = pixels / qMax(symbolSize.width, symbolSize.height);
            NSRect target = NSMakeRect((pixels - symbolSize.width * scale) / 2, (pixels - symbolSize.height * scale) / 2,
                                       symbolSize.width * scale, symbolSize.height * scale);

            QImage image(pixels, pixels, QImage::Format_ARGB32_Premultiplied);
            image.fill(Qt::transparent);

            CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
            CGContextRef context = CGBitmapContextCreate(image.bits(), pixels, pixels, 8, image.bytesPerLine(), colorSpace,
                                                         kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
            CGColorSpaceRelease(colorSpace);

            NSGraphicsContext* nsContext = [NSGraphicsContext graphicsContextWithCGContext:context flipped:NO];
            [NSGraphicsContext saveGraphicsState];
            [NSGraphicsContext setCurrentContext:nsContext];
            [symbol drawInRect:target fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
            [NSGraphicsContext restoreGraphicsState];
            CGContextRelease(context);

            if (size) {
                *size = image.size();
            }
            return image;
        }
    }
};

NativeChrome::NativeChrome(QObject* parent)
    : QObject(parent)
{
}

NativeChrome::~NativeChrome()
{
    [(MLToolbarController*)m_Native release];
}

// Qt's application menu still says "Preferences..."; macOS 13 and later say "Settings…".
// Qt re-reads the label through this translation whenever it syncs the menu, so answering
// it here keeps the new label (a language translator installed later still takes over).
class AppMenuTranslator : public QTranslator
{
public:
    using QTranslator::QTranslator;

    QString translate(const char* context, const char* sourceText, const char* disambiguation, int n) const override
    {
        Q_UNUSED(disambiguation)
        Q_UNUSED(n)
        if (qstrcmp(context, "MAC_APPLICATION_MENU") == 0 && qstrcmp(sourceText, "Preferences...") == 0) {
            return QStringLiteral("Settings…");
        }
        return QString();
    }

    bool isEmpty() const override
    {
        return false;
    }
};

void NativeChrome::registerTypes(QQmlEngine* engine)
{
    QCoreApplication::installTranslator(new AppMenuTranslator(QCoreApplication::instance()));

    engine->addImageProvider("sfsymbol", new SfSymbolImageProvider());
    qmlRegisterSingletonType<NativeChrome>("NativeChrome", 1, 0, "NativeChrome",
                                           [](QQmlEngine*, QJSEngine*) -> QObject* {
                                               return new NativeChrome();
                                           });
}

bool NativeChrome::isEnabled() const
{
    return true;
}

void NativeChrome::attach(QQuickWindow* window)
{
    // Only a Cocoa window has an NSView behind it (not, say, the offscreen platform)
    if (window == nullptr || m_Native != nullptr || QGuiApplication::platformName() != QLatin1String("cocoa")) {
        return;
    }

    NSView* qtView = reinterpret_cast<NSView*>(window->winId());
    NSWindow* nsWindow = qtView.window;
    if (nsWindow == nil) {
        return;
    }

    // Reopen where the window was last time (setting the name restores the saved frame),
    // unless the user asked for a maximized or full-screen window
    if (window->visibility() == QWindow::Windowed) {
        [nsWindow setFrameAutosaveName:kWindowFrameName];
    }

    // Toolbar in the title bar, with the title and traffic lights, as in Finder and Safari.
    // On macOS 26 and later the system draws its items on Liquid Glass.
    MLToolbarController* controller = [[MLToolbarController alloc] initWithChrome:this];
    m_Native = controller;
    nsWindow.toolbar = controller->toolbar;
    nsWindow.toolbarStyle = NSWindowToolbarStyleUnified;
    nsWindow.titlebarAppearsTransparent = YES;
    updateToolbar();

    // Translucent glass behind Moonlight's content. The Qt view draws on top with
    // a transparent background. NSGlassEffectView is macOS 26+; older systems get
    // the window-background vibrancy material.
    nsWindow.opaque = NO;
    nsWindow.backgroundColor = NSColor.clearColor;

    NSView* frameView = qtView.superview;
    NSView* backdrop = nil;
    Class glassClass = NSClassFromString(@"NSGlassEffectView");
    if (glassClass != nil) {
        backdrop = [[glassClass alloc] initWithFrame:frameView.bounds];
        if ([backdrop respondsToSelector:@selector(setCornerRadius:)]) {
            [(id)backdrop setCornerRadius:0];
        }
        // A light wash of the window color keeps text readable over busy desktops
        if ([backdrop respondsToSelector:@selector(setTintColor:)]) {
            [(id)backdrop setTintColor:[NSColor.windowBackgroundColor colorWithAlphaComponent:0.45]];
        }
    }
    else {
        NSVisualEffectView* effect = [[NSVisualEffectView alloc] initWithFrame:frameView.bounds];
        effect.material = NSVisualEffectMaterialUnderWindowBackground;
        effect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        effect.state = NSVisualEffectStateFollowsWindowActiveState;
        backdrop = effect;
    }
    backdrop.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [frameView addSubview:backdrop positioned:NSWindowBelow relativeTo:qtView];
    [backdrop release];
}

void NativeChrome::setWindowGeometry(QQuickWindow* window, qreal x, qreal y, qreal width, qreal height, bool animate)
{
    if (window == nullptr) {
        return;
    }

    NSWindow* nsWindow = QGuiApplication::platformName() == QLatin1String("cocoa") ?
                             reinterpret_cast<NSView*>(window->winId()).window : nil;
    if (nsWindow == nil || !animate) {
        window->setGeometry(qRound(x), qRound(y), qRound(width), qRound(height));
        return;
    }

    // Apply the change in the content area to the whole frame (title bar and toolbar
    // included), converting Qt's top-left origin to Cocoa's bottom-left one
    QRect current = window->geometry();
    NSRect frame = nsWindow.frame;
    CGFloat top = NSMaxY(frame) - (y - current.y());
    frame.origin.x += x - current.x();
    frame.size.width += width - current.width();
    frame.size.height += height - current.height();
    frame.origin.y = top - frame.size.height;

    [nsWindow setFrame:frame display:YES animate:YES];
}

static NSWindow* nativeWindow(QQuickWindow* window)
{
    if (window == nullptr || QGuiApplication::platformName() != QLatin1String("cocoa")) {
        return nil;
    }
    return reinterpret_cast<NSView*>(window->winId()).window;
}

void NativeChrome::setRememberWindowFrame(QQuickWindow* window, bool remember)
{
    NSWindow* nsWindow = nativeWindow(window);
    if (nsWindow == nil) {
        return;
    }

    if (remember) {
        // Keep the window where it is now (setting the name alone would jump back to
        // the frame saved before it was turned off)
        [nsWindow saveFrameUsingName:kWindowFrameName];
        [nsWindow setFrameAutosaveName:kWindowFrameName];
    }
    else {
        [nsWindow setFrameAutosaveName:@""];
    }
}

void NativeChrome::showAboutPanel()
{
    [NSApp orderFrontStandardAboutPanel:nil];
    if (@available(macOS 14.0, *)) {
        [NSApp activate];
    }
    else {
        [NSApp activateIgnoringOtherApps:YES];
    }
}

QStringList NativeChrome::appMenuItems() const
{
    QStringList items;
    if (NSApp.mainMenu.numberOfItems == 0) {
        return items;
    }
    NSMenu* appMenu = [NSApp.mainMenu itemAtIndex:0].submenu;
    [appMenu update];
    for (NSMenuItem* item in appMenu.itemArray) {
        if (item.isSeparatorItem || item.isHidden) {
            continue;
        }
        BOOL enabled = item.target != nil && [item.target respondsToSelector:@selector(validateMenuItem:)]
                           ? [item.target validateMenuItem:item] : item.isEnabled;
        items.append(QString::fromNSString(item.title) + (enabled ? "|enabled" : "|disabled"));
    }
    return items;
}

QString NativeChrome::symbol(const QString& name, const QColor& color) const
{
    return QStringLiteral("image://sfsymbol/%1/%2").arg(name, color.name(QColor::HexRgb).mid(1));
}

void NativeChrome::updateToolbar()
{
    [(MLToolbarController*)m_Native refresh];
}
