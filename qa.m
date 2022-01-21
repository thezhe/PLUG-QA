% MIT License

  % Copyright (c) 2022 TheZhe

  % Permission is hereby granted, free of charge, to any person obtaining a copy
  % of this software and associated documentation files (the "Software"), to deal
  % in the Software without restriction, including without limitation the rights
  % to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  % copies of the Software, and to permit persons to whom the Software is
  % furnished to do so, subject to the following conditions:

  % The above copyright notice and this permission notice shall be included in all
  % copies or substantial portions of the Software.

  % THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  % IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  % FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  % AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  % LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  % OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  % SOFTWARE.

% qa.m (https://github.com/thezhe/PLUG-QA)
  %
  % Run test cases on an audio plugin (set the default params to the most extreme/prone to artifacts)
  %
  % Requirements:
  % - The SOUL CLI (soul.exe) must be part of the system PATH
  % - The plugin must have 2 inputs and 2 outputs (stereo to stereo)
  % - The plugin must be one of the following formats: .soul, .soulpatch, .vst, .vst3, .dll, or .component
  %
  % Arguments:
  % - Fs:  sampling rate; only values in the range [44100, 96000] are officially supported
  %
  % Outputs:
  % - Graphs of test cases 
  % - logs in terminal
  % - Generated .wav files (lossless, 24-bit, 'Fs' sampling rate)
  %
  % Other useful info:
  % - See 'Inputs' section for more info on each test case
  % - Experiencing issues? Try deleting 'inputs/' and 'output/' or restarting Octave

% TaskList
  % 
  % Current Tasks:
  % - plugTime depends on soulpatch sources (parse json)
  % - support arbitrary channel count
  %
  % Future Tasks:
  % - set plugin parameters? May have to write my own PluginRunner

function qa(Plug, Fs, Bits)
%%==============================================================================
%% Main Script

  SEP = filesep();

  %set RENDER_CMD
  [PLUG_DIR, PLUG_NAME, PLUG_EXT] = fileparts (Plug);
  RENDER_CMD = '';
  if (strEq (PLUG_EXT, '.soul') || strEq (PLUG_EXT, '.soulpatch'))
    if (ispc() || ismac() || isunix())
      RENDER_CMD = 'soul render';
    else
      error ('OS must be Windows, Mac, or Linux');
    endif
  elseif (strEq (PLUG_EXT, '.vst') || strEq (PLUG_EXT, '.vst3') || strEq (PLUG_EXT, '.dll') || strEq (PLUG_EXT, '.component'))
    if (ispc())
      RENDER_CMD = ['.' SEP 'PluginRunner' SEP 'PluginRunner.exe'];
    elseif (ismac())
      RENDER_CMD = ['.' SEP 'PluginRunner' SEP 'PluginRunnerMac'];
    elseif (isunix())
      RENDER_CMD = ['.' SEP 'PluginRunner' SEP 'PluginRunnerLinux'];
    else
      error ('OS must be Windows, Mac, or Linux');
    endif
  else
    error ('Only .soul, .soulpatch, .vst, .vst3, .dll, and .component plugins supported');
  endif

  %MORE CONSTANTS
  DIR_SIGNALS_IN = './data/signals/in';
  DIR_SIGNALS_OUT = './data/signals/out';
  DIR_AUDIO_IN = './data/audio/in';
  DIR_AUDIO_OUT = './data/audio/out';

  %required packages
  pkg load signal; %specgram
  pkg load statistics; %hist3d 

  %timestamp
  timestamp = strftime ("%Y-%m-%d %H:%M:%S", localtime (time ()));
  printf('\n++++++++++++++++++++++++++++++++++++++++\n');
  printf(['qa(''' Plug ''', ' num2str(Fs) ', ' num2str(Bits) ')\n' timestamp '\n']);
  printf('++++++++++++++++++++++++++++++++++++++++\n');

  %render '/DIR_SIGNALS_IN'
  persistent frequency = 0;
  persistent qaTime = 0;
  [qaInfo, ~, ~] = stat('qa.m');

  if (~isfolder(DIR_SIGNALS_IN) || qaInfo.mtime ~= qaTime || Fs ~= frequency)
    genSignals(DIR_SIGNALS_IN, Fs, Bits);
  endif

  %render '/outputs'
  persistent plugTime = 0;
  [plugInfo, ~, ~] = stat(Plug);

  if (plugInfo.mtime ~= plugTime || qaInfo.mtime ~= qaTime || ~isfolder(DIR_AUDIO_OUT))
      renderDir(DIR_AUDIO_IN, DIR_AUDIO_OUT);
  endif

  isStableDir(DIR_AUDIO_OUT);

  if (plugInfo.mtime ~= plugTime || qaInfo.mtime ~= qaTime || ~isfolder(DIR_SIGNALS_OUT) || Fs ~= frequency)
    plugTime = plugInfo.mtime;
    qaTime = qaInfo.mtime;
    frequency = Fs;

    renderDir(DIR_SIGNALS_IN, DIR_SIGNALS_OUT);
  endif

  %plot results using '/DIR_SIGNALS_IN' and '/outputs'
  plotSignalsInOut(DIR_SIGNALS_IN, DIR_SIGNALS_OUT);

  printf('\n');
%%==============================================================================
%% High-Level
  function genSignals(directory, fs, bits)
    %%  Generate input signals 
    %
    % All signals normalized to 0.5 except except for 'dBRamp.wav'
    %%

    mkdir(directory);

    printf(['\nGenerating signals in ' directory '\n']);

    genPulse(directory, fs, bits);
    gendBRamp(directory, fs, bits);
    genSineRamp(directory, fs, bits);
    genImpulse(directory, fs, bits);
    genSineSweep(directory, fs, bits, 10);
    genSineSweep(directory, fs, bits, 2);
    genBSine(directory, fs, bits);
    genSine1k(directory, fs, bits);
    genZerosSine1k(directory, fs, bits);
  endfunction
  
  function renderDir(directoryIn, directoryOut)
    %% Render .wav files from 'directoryIn' into 'directoryOut'

    mkdir (directoryOut);

    printf(['\nRendering ' directoryIn ' into ' directoryOut '\n\n']);

    wavIn = glob([directoryIn '/*.wav']);
    for i=1:numel(wavIn)
      [~, name, ~] = fileparts (wavIn{i});
      render (wavIn{i}, [directoryOut '/' name '.wav']);
    endfor
  endfunction
  
  function isStableDir(directory)
    printf(['\nTesting stability of ' directory '\n\n']);

    wavFiles = glob([directory '/*.wav']);
    for i=1:numel(wavFiles)
      isStable(wavFiles{i});
    endfor
  endfunction

  function plotSignalsInOut(directorySignalsIn, directorySignalsOut)
    %%  Plot results using .wav files from 'directorySignalsIn' and 'directorySignalsIn'

    printf(['\nPlotting ' directorySignalsIn ' vs ' directorySignalsOut '\n\n']);

    grid off

    plotSignal([directorySignalsOut '/Pulse.wav'], 'Step Response', 2, [2, 3, 1]); 
    plotWaveshaper([directorySignalsOut '/dBRamp.wav'], [directorySignalsIn '/dBRamp.wav'], true, 100, 'DC IO Plot', 2, [2, 3, 2]);
    plotWaveshaper([directorySignalsOut '/SineRamp.wav'], [directorySignalsIn '/SineRamp.wav'], false, 0, 'SineRamp IO Plot', 2, [2, 3, 3]);
    plotBode([directorySignalsOut '/Impulse.wav'], 'Impulse', 2, [2, 3, 4]);
    plotVectorscope([directorySignalsOut '/SineSweep2.wav'], 'SineSweep2 Vectorscope', 2, [2, 3, 6]);
    plotSpec([directorySignalsOut '/SineSweep10.wav'], true, 'SineSweep10 Spectrogram (BW)', 1, [1, 1, 1]);

    isStable([directorySignalsOut, '/Pulse.wav']);
    isStable([directorySignalsOut, '/Impulse.wav']);
    isStable([directorySignalsOut, '/SineRamp.wav']);
    isStable([directorySignalsOut, '/SineSweep2.wav']);
    isStable([directorySignalsOut, '/SineSweep10.wav']);
    isStable([directorySignalsOut, '/BSine.wav']);
    isStable([directorySignalsOut, '/Sine1k.wav']);
    isStable([directorySignalsOut, '/ZerosSine1k.wav']);
    
    gainDiff ([directorySignalsOut '/SineSweep10.wav']); 

    function gainDiff (file2)
      %% Use with 'outputs/SinSweep.wav' to find makeup gain such that the max output amplitude is 0dB across all sweeped frequencies
      %  In practice the makeup gain is usually more than the estimated value.
      [y, ~] = audioread(file2);

      dBDiff = gainTodB (max(max(y)) / 0.5); #input is normalized to 0.5

      printf("Estimated required makeup gain: %.1f dB.\n", -dBDiff);
    endfunction
  endfunction
  
%%==============================================================================
%% Generate Signals

  function genBSine(directory, fs, bits)
    %%  Generate (0.5/6)*sin + (2.5/6)*cos with frequencies 2kHz and 18kHz
    %
    % Notes:
    % - 0.5 normalized
    % - Test: stability
    % - Length: 0.25 second
    % - See Fig. 4 in https://dafx2019.bcu.ac.uk/papers/DAFx2019_paper_3.pdf
    %%

    n = (0:ceil((Fs-1)/4)).';

    A1 = 0.5/6;
    A2 = 2.5/6;

    wd1 = pi*4000/fs;
    wd2 = pi*36000/fs;

    y = A1 * sin(wd1*n) + A2 * cos(wd2*n);

    audiowrite([directory '/BSine.wav'], [y, y], fs, 'BitsPerSample', bits);
  endfunction

  function gendBRamp(directory, fs, bits)
    %% Generate a linear ramp on the dB scale from -60 dB to 0 dB 
    %
    % Notes:
    % - 0.5 normalized
    % - Tests: decibel input/output mapping for dc signals ('outputs/dBRamp.wav' vs 'input/dBRamp.wav' waveshaper plot a.k.a 'DC IO Plot')
    % - Length: 2 seconds
    %%

    y = dBtoGain(linspace(-60, 0, 2*Fs)).';

    audiowrite([directory '/dBRamp.wav'], [y, y], fs, 'BitsPerSample', bits);
  endfunction 

  function genImpulse(directory, fs, bits)  
    %% Generate an impulse with amplitude 0.5
    %
    % Notes:
    % - 0.5 normalized
    % - Tests: frequency response ('outputs/Impulse.wav' Bode plot a.k.a. 'Magnitude/Phase Response'), stability
    % - Length: 1 second
    %%

    y = [0.5; zeros(Fs-1, 1)];

    audiowrite([directory '/Impulse.wav'], [y, y], fs, 'BitsPerSample', bits);
  endfunction

  function genPulse(directory, fs, bits)
    %% Generate a pulse signal with value 0.5 and 0.25 for the first and second halves
    % 
    % Notes:
    % - 0.5 normalized
    % - Tests: step response and attack/release response ('outputs/Pulse.wav' signal plot a.k.a. 'Step Response'), stability
    % - Length: 1 second
    %%

    y = zeros(Fs, 1);

    y(1:(end/2)) = 0.5;
    y((end/2 + 1):end) = 0.25;

    audiowrite([directory '/Pulse.wav'], [y, y], fs, 'BitsPerSample', bits);
  endfunction

  function genSineSweep(directory, fs, bits, len)
    %% Generate a sin sweep from 20 to 20kHz
    % 
    % Notes:
    % - 0.5 normalized
    % Tests: harmonic/inharmonic distortion and aliasing ('outputs/SinSweep.wav' spectrogram), estimated makeup gain, stability
    % Length: 10 seconds
    % See: https://github.com/julian-parker/DAFX-AntiAliasing
    %%

    t = (0:1/Fs:(len - 1/ Fs)).';

    y = 0.5 * chirp (t, 0, len, 20000);
    
    audiowrite([directory '/SineSweep' num2str(len) '.wav'], [y, y], fs, 'BitsPerSample', bits);
  endfunction
  
  function genSineRamp(directory, fs, bits)
    %% Generate a sin that fades in linearly
    % 
    % Notes:
    % - 0.5 normalized
    % - Length: 0.025 seconds
    % - Tests: hysteresis in the input output plot ('outputs/SinRamp.wav' vs 'inputs/SinRamp.wav' waveshaper plot a.k.a. 'SinRamp IO Plot'), stability
    %%

    nMax = ceil(0.025*Fs)-1;
    n = (0:nMax).';

    A = (0:0.5/nMax:0.5).';

    wd = pi*880/Fs;

    y = A.*sin(wd*n);

    audiowrite([directory '/SineRamp.wav'], [y, y], fs, 'BitsPerSample', bits);
  endfunction

  function genSine1k(directory, fs, bits)
    %% Generate a 1kHz sin
    % 
    % Notes:
    % - 0.5 normalized
    % - Length: 1 second
    % - Tests: stability
    %%

    n = (0:ceil(Fs-1)).';

    wd = pi*2000/Fs;

    y = 0.5 * sin (wd*n);

    audiowrite([directory '/Sine1k.wav'], [y, y], fs, 'BitsPerSample', bits);
  endfunction

  function genZerosSine1k(directory, fs, bits)
    %% Generate 0.5 seconds of zeros followed by 0.5 seconds of Sin1k
    % 
    % Notes:
    % - 0.5 normalized
    % - Length: 1 second
    % - Tests: stability
    %%

    half = ceil((Fs-1)/2);

    n = (0:half).';

    y = zeros (2*half, 1);

    wd = pi*2000/Fs;

    y(half:end) = 0.5 * sin (wd * n);

    audiowrite([directory '/ZerosSine1k.wav'], [y, y], fs, 'BitsPerSample', bits);
  endfunction
  
%%==============================================================================
%% Plotting

  function plotBode(file, ttl, fig, sp)
    %% Plot magnitude (dB) and phase (radians) responses of an impulse response
    %
    % Notes:
    % - 'file': audio file path
    % - 'ttl': title
    % - 'fig' - figure number
    % - 'sp' - three element array to set the subplot
    %%

    %FFT
    [x, fs] = audioread(file);
    n = length(x);
    df = fs/n;
    f = 0:df:(fs/2);
    y = fft(x);
    y = y(1:(n/2)+1, :) * 2;  

    %magnitude
    mag = gainTodB(abs(y));

    printf('DC magnitude response: %s dB\n', num2str(mag(1)));

    mag = mag(2:length(mag), :);
    fmag = f(2:end);
    [fmagR1, magR1] = reducePlot(fmag, mag(:, 1), 0.0001);
    [fmagR2, magR2] = reducePlot(fmag, mag(:, 2), 0.0001);
    
    figure(fig, 'units', 'normalized', 'position', [0.1 0.1 0.8 0.8]);
    subplot(sp(1), sp(2), sp(3));
    hold on 
      set(gca,'xscale','log');
      set(gca, "linewidth", 1, "fontsize", 16)

      title('\fontsize{20}Magnitude Response');
      xlabel('\fontsize{16}frequency (Hz)');
      ylabel('\fontsize{16}magnitude (dB)');

      plot(fmagR1, magR1, 'LineWidth', 1.5);
      plot(fmagR2, magR2, 'LineWidth', 1.5);
      xlim([fmag(1), 20000]);
      ylim([-40, 6]);
    hold off

    %phase
    p = angle(y);
    dc = sprintf('%.1f', p (1));
    ny = sprintf('%.1f', p (end));

    p = p(2:length(p), :);
    fp = f(2:end);
    [fpR1, pR1] = reducePlot(fp, p(:, 1), 0.0001);
    [fpR2, pR2] = reducePlot(fp, p(:, 2), 0.0001);

    subplot(sp(1), sp(2), sp(3)+1);
    hold on
      set(gca,'xscale','log');
      set(gca, "linewidth", 1, "fontsize", 16);
      title(['\fontsize{20}Phase Response']);
      xlabel('\fontsize{16}frequency (Hz)');
      ylabel('\fontsize{16}phase (rad)');
      xlim([fp(1), 20000]);
      ylim([-pi, pi]);
      
      plot(fpR1, pR1, 'LineWidth', 1.5);
      plot(fpR2, pR2, 'LineWidth', 1.5);
    hold off
  endfunction

  function plotSpec(file, binary, ttl, fig, sp)
    %%  Plot a spectrogram of a file (max magnitude between all channels)

    [x, fs] = audioread(file);

    n = floor (1024 * (fs/44100));
    win = blackman(n);
    overlap = floor (8 * (fs/44100));
    [S0, f, t] = specgram (x(:,1), n, fs, win, overlap);
    [S1, ~, ~] = specgram (x(:,2), n, fs, win, overlap);

    %bandlimit and normalize
    S0 = abs(S0);
    S1 = abs(S1);
    idx = (S0 > S1);
    S1(idx) = 0;
    S0(!idx) = 0;
    S = S0 + S1;
    S = S/(max(max(S)));
    
    %Black and white binary image
    if (binary)
      S(abs(S) > 0.001) = 1;
    endif

    %clamp to [-60, 0dB]
    S(abs(S)<0.001) = 0.001;
    
    %spectogram
    figure(fig, 'units', 'normalized', 'position', [0.1 0.1 0.8 0.8]);
    subplot(sp(1), sp(2), sp(3));
    hold on
      imagesc (t, f, gainTodB(S));
      colormap (1-gray);
      ylim([0, 20000]);
      xlim([0, audioinfo(file).Duration]);
      set(gca, "fontsize", 16);
      title(['\fontsize{20}' ttl]);
      ylabel('\fontsize{16}frequency (Hz)');
      xlabel('\fontsize{16}time (s)');
    hold off
  endfunction

  function plotSignal(file, ttl, fig, sp)
    %% Plot a signal from an audio file

    [y, fs] = audioread(file);
    info = audioinfo(file);
    t = 0:1/fs:info.Duration-(1/fs);

    [tR1, yR1] = reducePlot(t, y(:, 1), 0.0001);
    [tR2, yR2] = reducePlot(t, y(:, 2), 0.0001);

    figure(fig, 'units', 'normalized', 'position', [0.1 0.1 0.8 0.8]);
    subplot(sp(1), sp(2), sp(3));    
    hold on
      set(gca, "linewidth", 1, "fontsize", 16);
      title(['\fontsize{20}' ttl]);
      xlabel('\fontsize{16}t (seconds)');
      ylabel('\fontsize{16}amplitude');

      plot(tR1, yR1, 'LineWidth', 1.5);
      plot(tR2, yR2, 'LineWidth', 1.5);
      ylim([-1, 1]);
    hold off
  endfunction

  function plotWaveshaper(file2, file1, dB, res, ttl, fig, sp)
    %% Plot samples of file2 vs file1
    %
    % Notes:
    % - 'dB': Set to true to make axes dB scale
    % - 'res': Set number of points to plot (decimate the signal); set to 0 to plot all points
    %%

    [y, fs] = audioread(file2);
    [x, ~] = audioread(file1);

    if (dB)
      y = gainTodB(y); 
      x = gainTodB(x); 
    end

    if (res>1)
      Q = floor(fs/res);
      last = length(x)-mod(length(x), Q);
      x = x(1:Q:last, :);
      y = y(1:Q:last, :);
    end

    figure(fig, 'units', 'normalized', 'position', [0.1 0.1 0.8 0.8]);
    subplot(sp(1), sp(2), sp(3));
    hold on;
      set(gca, "linewidth", 1, "fontsize", 16)
      title(['\fontsize{20}' ttl]);
      if(dB)
        xlabel('\fontsize{16}input (dB)');
        ylabel('\fontsize{16}output (dB)');
        xlim([-60, 0]);
        ylim([-60, 0]);
      else
        xlabel('\fontsize{16}input');
        ylabel('\fontsize{16}output');
        xlim([-0.5, 0.5]);
        ylim([-1, 1]);
      end

      scatter(x(:, 1), y(:, 1), 1, 'filled');
      scatter(x(:, 2), y(:, 2), 1, 'filled');
    hold off
  endfunction

  function plotVectorscope(file, ttl, fig, sp)
    %% Plot a vector scope from a stereo file 
      % See: https://www.rtw.com/en/blog/focus-the-vectorscope.html

    [y, fs] = audioread(file);

    figure(fig, 'units', 'normalized', 'position', [0.1 0.1 0.8 0.8]);
    subplot(sp(1), sp(2), sp(3));
    hold on;
      set(gca, "linewidth", 1, "fontsize", 16)
      title(['\fontsize{20}' ttl]);

      xlabel('\fontsize{16}R');
      ylabel('\fontsize{16}L');
      xlim([-1, 1]);
      ylim([-1, 1]);

      y = y/max(max(y)); %normalize

      [counts, centers] = hist3(y, [100, 100]);
      counts(counts > 0.001) = 1;
      imagesc(centers{1}, centers{2}, counts);
      colormap (1-gray);
      camroll (45);
    hold off 
  endfunction

%%==============================================================================
%% Utility

  function isStable(file)
    %%  Print a warning if any samples > 0.99 or < 0.01

    [y, ~] = audioread(file);
    
    if (any(abs(y) > 0.99))
      warning("%s is unstable or increases peak level to clipping.\n", file);
    endif

    if (max(y) < 0.01)
      warning("%s is very quite or slient.\n", file);
    endif 
  endfunction

  function render(wavIn, wavOut)
    status = 0;

    if (strEq(RENDER_CMD, 'soul render'))
      [status, ~] = system([RENDER_CMD ' ' Plug ' --input=' wavIn ' --output=' wavOut ' --rate=' num2str(audioinfo(wavIn).SampleRate) ' --bitdepth=' num2str(audioinfo(wavIn).BitsPerSample)]); 
    else
      [status, ~] = system([RENDER_CMD ' ' Plug ' ' wavIn ' ' wavOut]);
    endif

    if (status != 0)
        error ('See message printed above');
    endif

  endfunction

  function y = strEq (str1, str2)
    if (length(str1) != length(str2))
      y = false;
    else
      y = strncmp (str1, str2, length(str1));
    endif
  endfunction

  function y = gainTodB(x)
    y = 20.*log10(x);
    y(y<-100) = -100;
  endfunction

  function y = dBtoGain(x)
    x(x<-100) = -100;
    y = 10.^(x/20);
  endfunction

  function [xR, yR] = reducePlot(x, y, thrdy)
    %% Reduce the points to plot by setting a threshold for dy
    %
    % Notes:
    % - First and last elements are always plotted
    % - Points with abs(dy) > thrdy and points 1 sample before these points are plotted
    %
    % Example:
    %   x = 0:5;
    %   y = [0; 0; 1; 0; 0; 0];
    %   [xR, yR] = reducePlot(x, y, 0.1)
    %   xR = 
    %     0 1 2 3 5 
    %   yR =
    %     0 
    %     0
    %     1
    %     0
    %     0
    %%

    dy = y(2:end) - y(1:end-1);
    dy = abs(dy) > thrdy;
    dy = [1; dy(1:end)];
    dy(1:end-1) = dy(1:end-1) + dy(2:end);
    dy(end) = 1;
    dy(dy>1) = 1;
    idx = logical(dy);

    xR = x(idx);
    yR = y(idx);
  endfunction

endfunction
