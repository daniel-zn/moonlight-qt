#include "micnoisefilter.h"

#include <algorithm>

#ifdef HAVE_RNNOISE
extern "C" {
#include "rnnoise/rnnoise.h"
}
#endif

namespace {
    // One-pole high-pass at about 75 Hz for 48 kHz input
    constexpr float kHighPassCoefficient = 0.99f;

    // RNNoise's voice probability below which a block counts as quiet
    constexpr float kVoiceThreshold = 0.5f;

    // Open the gate after this many voice blocks (10 ms each) in a row. A key press
    // fits in one block, so it can't open the gate on its own.
    constexpr int kGateOpenBlocks = 2;

    // Keep the gate open this many quiet blocks after speech so word endings aren't
    // clipped
    constexpr int kGateHoldBlocks = 20;
}

MicNoiseFilter::MicNoiseFilter()
    : m_State(nullptr)
    , m_HighPassPrevIn(0.0f)
    , m_HighPassPrevOut(0.0f)
    , m_GateGain(1.0f)
    , m_QuietBlocks(kGateHoldBlocks + 1)
    , m_VoiceBlocks(0)
{
#ifdef HAVE_RNNOISE
    m_State = rnnoise_create(nullptr);
#endif
}

MicNoiseFilter::~MicNoiseFilter()
{
#ifdef HAVE_RNNOISE
    if (m_State != nullptr) {
        rnnoise_destroy(m_State);
    }
#endif
}

void MicNoiseFilter::process(int16_t* samples, int count)
{
    if (m_State == nullptr) {
        return;
    }

#ifdef HAVE_RNNOISE
    float block[kBlockSize];
    for (int offset = 0; offset + kBlockSize <= count; offset += kBlockSize) {
        int16_t* pcm = samples + offset;

        // RNNoise works on float samples in 16-bit range
        for (int i = 0; i < kBlockSize; i++) {
            const float in = pcm[i];
            m_HighPassPrevOut = kHighPassCoefficient * (m_HighPassPrevOut + in - m_HighPassPrevIn);
            m_HighPassPrevIn = in;
            block[i] = m_HighPassPrevOut;
        }

        const float voiceProbability = rnnoise_process_frame(m_State, block, block);

        // Open the gate on sustained speech; close it after a short hold
        if (voiceProbability >= kVoiceThreshold) {
            m_VoiceBlocks++;
            if (m_VoiceBlocks >= kGateOpenBlocks) {
                m_QuietBlocks = 0;
            }
        }
        else {
            m_VoiceBlocks = 0;
            m_QuietBlocks++;
        }
        const float targetGain = m_QuietBlocks <= kGateHoldBlocks ? 1.0f : 0.0f;

        // Ramp the gain across the block so the gate doesn't click
        const float startGain = m_GateGain;
        for (int i = 0; i < kBlockSize; i++) {
            const float gain = startGain + (targetGain - startGain) * (i + 1) / kBlockSize;
            pcm[i] = static_cast<int16_t>(std::clamp(block[i] * gain, -32768.0f, 32767.0f));
        }
        m_GateGain = targetGain;
    }
#else
    (void)samples;
    (void)count;
#endif
}
