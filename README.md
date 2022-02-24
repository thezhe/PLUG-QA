![PLUG-QA_logo](logo.png)
# PLUG-QA
PLUG-QA is a Quality Assurance (QA) script for audio plugin development (`.vst3`, `.component`, `.dll`, `.vst`, `.soulpatch`, and `.soul`). It displays step, frequency, gain, waveshaper, vectorscope, and spectrogram responses and renders audio files.

## NOTE: 
- This project is a work in progress. Only maintained for Octave on Windows, but should work for other OSes and Matlab with minimal tinkering.
- All non-SOUL plugins must support *-2 channel IO even if that isn't the intended use case. This is not only a requirement for PLUG-QA, but also a common requirement for many DAWs.

## Dependencies:  
- [Octave 6.4.0](https://www.gnu.org/software/octave/download) 
- [SOUL CLI 1.0.82](https://github.com/soul-lang/SOUL/releases/tag/1.0.82) (add to system PATH if testing .soulpatch or .soul plugins)
- Git Submodules (run `sh updateSub.sh` in Bash or `.\updateSub.ps1` in PowerShell)

## Useful Tools:
- [VS Code](https://code.visualstudio.com/)  
- [wav-preview](https://github.com/sukumo28/wav-preview)

## Usage
- Place audio files to render in `audioIn`
```matlab
octave qa.m PluginPath
```
- Runs all tests at 44.1 and 96 kHz sampling rates
- PluginPath must be a string (i.e., wrap it in quotes)

## Outputs
- Logs go to stdout
- Graphs and rendered audio placed in `results`
- Non-zero exit code on common errors

## Contributing
Please post bugs in issues and features requests in discussions. Pull requests are allowed and encouraged, especially if they add new tests to `qaFunc.m`!

## Projects using PLUG-QA
[SOUL-VA](https://github.com/thezhe/SOUL-VA)
