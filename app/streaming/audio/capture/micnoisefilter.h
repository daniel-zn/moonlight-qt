#pragma once

#include <cstdint>

struct DenoiseState;

// Cleans up 48 kHz mono microphone audio before it's sent to the host: a gentle
// low-cut for rumble, RNNoise noise suppression (keyboards, fans, hum), and a
// gate that fades to silence when nobody is talking. Suppression is only built
// on macOS; elsewhere process() leaves the audio untouched.
class MicNoiseFilter
{
public:
    // Samples per processing block (10 ms)
    static constexpr int kBlockSize = 480;

    MicNoiseFilter();
    ~MicNoiseFilter();

    MicNoiseFilter(const MicNoiseFilter&) = delete;
    MicNoiseFilter& operator=(const MicNoiseFilter&) = delete;

    // Filters in place. count must be a multiple of kBlockSize.
    void process(int16_t* samples, int count);

private:
    DenoiseState* m_State;
    float m_HighPassPrevIn;
    float m_HighPassPrevOut;
    float m_GateGain;
    int m_QuietBlocks;
    int m_VoiceBlocks;
};
