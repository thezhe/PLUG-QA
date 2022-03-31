## Description
PLUG-QA is a Quality Assurance (QA) script for audio effect plugin development (`.vst3`, `.component`, `.dll`, `.vst`, `.soulpatch`, and `.soul`). It displays step, frequency, gain, waveshaper, vectorscope, and spectrogram responses and renders audio files.

## Dependencies:  
- [Octave 6.4.0](https://www.gnu.org/software/octave/download)*.
- [SOUL CLI 1.0.82](https://github.com/soul-lang/SOUL/releases/tag/1.0.82)*.
- [PluginRunner](https://github.com/jatinchowdhury18/PluginRunner).

##### *Install and add to system PATH

## Usage
```matlab
octave qa.m <plugin path>
```
#### Outputs (44.1 kHz):
- Logs go to stdout
- Figures and rendered audio placed in `results/`
- Non-zero exit code on common errors

## Passing Conditions
1. No runtime errors.
2. Spectrogram shows no aliasing partials above -60dB running on a plugin with the most aliasing-prone parameters*.
3. Common sense (e.g., a low-pass filter should have a low-pass frequency response).

##### *Only applies to nonlinear plugins. To find the 'most aliasing-prone parameters' set nonlinear parameters (e.g., drive) to max values. For nonlinear parameters (e.g., threshold) that do not linearly correlate with aliasing, set their values to approximately the most aliasing-prone values. Consequently, aliasing is practically inaudible, even though it may surpass -60dB for some untested signal/parameter combinations.

## Limitations: 
- Only tested on Windows x64 Octave, but should work on Matlab, Windows/Linux, and ARM with minimal tinkering.
- Does *not* replace unit testing, although PLUG-QA may not run on plugins that fail common unit tests.

# Examples
Below are some demonstations of the output figures after running on some [SOUL-VA](https://github.com/thezhe/SOUL-VA) plugins (hereinafter referred to as 'effects'). Please refer to [qaFunc.m](https://github.com/thezhe/PLUG-QA/blob/master/qaFunc.m) for a more in-depth explaination of test cases.

### Example 1: `TheDummy`
The effect passes signals through unmodified; therefore, the output figures plot the test signals. Notice how the step response input is a pulse signal with values 0.5 and 0.25 to measure overshoot/undershoot. The DC IO plot (a.k.a. compressor transfer function) and SinRamp IO plot (a.k.a. waveshaper plot) map, respectively, monotonically increasing DC and the product of a sin wave and ramp signal to their outputs.
![Dummy2](https://user-images.githubusercontent.com/42720670/143499549-a8484fe7-bb55-4c24-8242-aa6dd5be6b1c.png)  
![Dummy1](https://user-images.githubusercontent.com/42720670/143499553-e699e725-ad35-413c-9378-3121313d5d49.png)  
### Example 2: `TheBass` (nonlinearity = 200)
The effect is nonlinear. Even though Magnitude Response is specific to LTI systems, it accuractly predicts that `TheBass` tends to boost bass frequencies. The DC IO Plot is constant due to the effect's internal DC blocker.
![200_0](https://user-images.githubusercontent.com/42720670/147501416-b4dd38a7-3c66-49b3-8b57-07cc84e9f2ea.png)
![200_1](https://user-images.githubusercontent.com/42720670/147501419-4961ac5c-b33e-49fc-822b-9c117b886c2c.png)
### Example Effect 3: `TheBass` (nonlinearity = 500)
The effect is nonlinear, but does not pass PLUG-QA. Aliasing paritials greater than -60dB in peak amplitude appear as lines nonparallel to harmonics/inharmonics or random dots in SinSweep Spectrogram (BW). Unrelated to aliasing, DC noise also appears from 0 to 6 seconds. 
![500_0](https://user-images.githubusercontent.com/42720670/147501429-f1b6f600-2b86-40c1-a913-f888c2f9ef35.png)
![500_1](https://user-images.githubusercontent.com/42720670/147501430-67f85641-2030-4946-bb75-9630ddbed1b7.png)
 
