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

% qaFunc.m (https://github.com/thezhe/PLUG-QA)

  % Run test cases on an audio plugin

  % Arguments:
  % - Plug: path to the plugin; must be a string!
  % - Fs:  sampling rate within the range [44100, 96000]

  % Outputs:
  % - Logs go to stdout
  % - Graphs and rendered audio placed in `results`
  % - Non-zero exit code on common errors

  % Notes:
  % - signals are 32 bit float, audio follows the bit depth in ./audioIn
  % - 2-2 channel IO supported for Non-SOUL plugins; 2-* supported for SOUL plugins

  % Issues? Try running 'qaClear'

function qaFunc (Plug, Fs)
%==============================================================================
% Main function                                                           
%==============================================================================

  %DIR_*
  DIR_RESULTS = 'results';
  DIR_AUDIO_OUT = ['./' DIR_RESULTS '/audioOut'];

  DIR_AUDIO_IN = './audioIn';

  DIR_SIGNALS_IN = './signals/in';
  DIR_SIGNALS_OUT = './signals/out';
  
  %EXTS_*
  EXTS_SOUL = cellstr(['.soulpatch'; '.soul']);
  EXTS_PLUGIN_RUNNER = cellstr (['.vst3'; '.component'; '.dll'; '.vst']);

  %PLUG*
  [PLUG_DIR, PLUG_NAME, PLUG_EXT] = fileparts (strrep (Plug, '\\', '/'));
  PLUG = [PLUG_DIR '/' PLUG_NAME PLUG_EXT ];

  %Starting Timestamp
  timestamp = strftime ("%Y-%m-%d %H:%M:%S", localtime (time ()));
  printf('\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n');
  printf(['qaFunc (' PLUG ', ' num2str(Fs) ')\n' timestamp '\n']);
  printf('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n');

  %Packages
  pkg load signal; %specgram
  pkg load statistics; %hist3d 

  %RENDER_CMD
  printf('\nParsing qaFunc arguments\n\n');

  if (Fs < 44100 || Fs > 96000)
    error ('Fs must be in the range [44100, 96000]');
  endif

  if (anyStrsEq (EXTS_SOUL, PLUG_EXT))
    systemChecked (['soul errors ' PLUG]);
    RENDER_CMD = 'soul render';
  elseif (anyStrsEq (EXTS_PLUGIN_RUNNER, PLUG_EXT))
    if (ispc())
      RENDER_CMD = '.\PluginRunner\PluginRunner.exe';
    elseif (ismac())
      RENDER_CMD = './PluginRunner/PluginRunnerMac';
    else
      RENDER_CMD = './PluginRunner/PluginRunnerLinux';
    endif
  else
    error ('Only .soulpatch, .soul, .vst3, .component, .dll, and .vst plugins supported');
  endif

  %MODIFIED_*
  persistent prevPlugTime = 0;
  persistent prevFs = 0;
  persistent prevQaTime = 0;

  currentPlugTime = getPlugTime (PLUG);
  currentFs = Fs;
  currentQaTime = getFileTime ('qaFunc.m');

  MODIFIED_PLUG = (prevPlugTime ~= currentPlugTime);
  MODIFIED_FS = (prevFs ~= currentFs);
  MODIFIED_QA = (prevQaTime ~= currentQaTime);

  prevPlugTime = currentPlugTime;
  prevFs = currentFs;
  prevQaTime = currentQaTime;

  %populate DIR_AUDIO_OUT
  if (MODIFIED_PLUG || ~isfolder (DIR_AUDIO_OUT) || MODIFIED_QA)
    renderDir (DIR_AUDIO_IN, DIR_AUDIO_OUT);
  endif

  %test DIR_AUDIO_OUT
  isStableDir(DIR_AUDIO_OUT);

  %populate DIR_SIGNALS_IN
  if (MODIFIED_FS || ~isfolder (DIR_SIGNALS_IN) || MODIFIED_QA )
    genSignals (DIR_SIGNALS_IN, Fs);
  endif

  %populate DIR_SIGNALS_OUT
  if (MODIFIED_FS || MODIFIED_PLUG || ~isfolder (DIR_SIGNALS_OUT) || MODIFIED_QA)
    renderDir (DIR_SIGNALS_IN, DIR_SIGNALS_OUT);
  endif
  
  %populate DIR_RESULTS/*.png
  plotSignalsInOut(DIR_SIGNALS_IN, DIR_SIGNALS_OUT);

  printf('\n');
%%==============================================================================
%% High-Level
  function genSignals(directory, fs)
    %%  Generate input signals 
    %
    % All signals stereo and normalized to 0.5 except except for 'dBRamp.wav'
    %%

    mkdir(directory);

    printf('\n================================================================================');
    printf(['\nGenerating signals in ' directory '\n\n']);

    genPulse(directory, fs);
    gendBRamp(directory, fs);
    genSineRamp(directory, fs);
    genImpulse(directory, fs);
    genSineSweep(directory, fs, 10);
    genSineSweep(directory, fs, 2);
    genBSine(directory, fs);
    genSine1k(directory, fs);
    genZerosSine1k(directory, fs);
  endfunction
  
  function renderDir(directoryIn, directoryOut)
    %% Render .wav files from 'directoryIn' into 'directoryOut'

    mkdir (directoryOut);

    printf('\n================================================================================');
    printf(['\nRendering ' directoryIn ' into ' directoryOut '\n\n']);

    wavIn = glob([directoryIn '/' '*.wav']);
    for i=1:numel(wavIn)
      [~, name, ~] = fileparts (wavIn{i});
      render (wavIn{i}, [directoryOut '/' name '.wav']);
    endfor
  endfunction
  
  function isStableDir(directory)
    printf('\n================================================================================');
    printf(['\nTesting stability of ' directory '\n\n']);

    wavFiles = glob([directory '/' '*.wav']);
    for i=1:numel(wavFiles)
      audioreadChecked(wavFiles{i});
    endfor
  endfunction

  function plotSignalsInOut(directorySignalsIn, directorySignalsOut)
    %%  Plot results using .wav files from 'directorySignalsIn' and 'directorySignalsIn'

    printf('\n================================================================================');
    printf(['\nPlotting ' directorySignalsIn ' vs ' directorySignalsOut '\n\n']);

    grid off

    plotSignal([directorySignalsOut '/' 'Pulse.wav'], 'Step Response', 2, [2, 3, 1]); 
    plotWaveshaper([directorySignalsOut '/' 'dBRamp.wav'], [directorySignalsIn '/' 'dBRamp.wav'], true, 100, 'DC IO Plot', 2, [2, 3, 2]);
    plotWaveshaper([directorySignalsOut '/' 'SineRamp.wav'], [directorySignalsIn '/' 'SineRamp.wav'], false, 0, 'SineRamp IO Plot', 2, [2, 3, 3]);
    plotBode([directorySignalsOut '/' 'Impulse.wav'], 'Impulse', 2, [2, 3, 4]);
    plotVectorscope([directorySignalsOut '/' 'SineSweep2.wav'], 'SineSweep2 Vectorscope', 2, [2, 3, 6]);
    saveas(2, [DIR_RESULTS '/signals2.png']);
    plotSpec([directorySignalsOut '/' 'SineSweep10.wav'], true, 'SineSweep10 Spectrogram (BW)', 1, [1, 1, 1]);
    saveas(1, [DIR_RESULTS '/signals1.png']);
  endfunction
  
%%==============================================================================
%% Generate Signals

  function genBSine(directory, fs)
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

    audiowrite([directory '/' 'BSine.wav'], [y, y], fs, 'BitsPerSample', 32);
  endfunction

  function gendBRamp(directory, fs)
    %% Generate a linear ramp on the dB scale from -60 dB to 0 dB 
    %
    % Notes:
    % - 0.5 normalized
    % - Tests: decibel input/output mapping for dc signals ('outputs/dBRamp.wav' vs 'input/dBRamp.wav' waveshaper plot a.k.a 'DC IO Plot')
    % - Length: 2 seconds
    %%

    y = dBtoGain(linspace(-60, 0, 2*Fs)).';

    audiowrite([directory '/' 'dBRamp.wav'], [y, y], fs, 'BitsPerSample', 32);
  endfunction 

  function genImpulse(directory, fs)  
    %% Generate an impulse with amplitude 0.5
    %
    % Notes:
    % - 0.5 normalized
    % - Tests: frequency response ('outputs/Impulse.wav' Bode plot a.k.a. 'Magnitude/Phase Response'), stability
    % - Length: 1 second
    %%

    y = [0.5; zeros(Fs-1, 1)];

    audiowrite([directory '/' 'Impulse.wav'], [y, y], fs, 'BitsPerSample', 32);
  endfunction

  function genPulse(directory, fs)
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

    audiowrite([directory '/' 'Pulse.wav'], [y, y], fs, 'BitsPerSample', 32);
  endfunction

  function genSineSweep(directory, fs, len)
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
    
    audiowrite([directory '/' 'SineSweep' num2str(len) '.wav'], [y, y], fs, 'BitsPerSample', 32);
  endfunction
  
  function genSineRamp(directory, fs)
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

    audiowrite([directory '/' 'SineRamp.wav'], [y, y], fs, 'BitsPerSample', 32);
  endfunction

  function genSine1k(directory, fs)
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

    audiowrite([directory '/' 'Sine1k.wav'], [y, y], fs, 'BitsPerSample', 32);
  endfunction

  function genZerosSine1k(directory, fs)
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

    audiowrite([directory '/' 'ZerosSine1k.wav'], [y, y], fs, 'BitsPerSample', 32);
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

    %read
    [y, fs] = audioreadChecked(file);
    
    %f
    n = length(y);
    df = fs/n;
    f = 0:df:(fs/2);

    %fft
    y = fft(y);
    y = y(1:(n/2)+1, :) * 2;  

    %dc magnitude
    printf(['DC magnitude responses: ' mat2str(gainTodB(abs (y (1, :)))) ' dB']);

    %limit to freq bins to [1, 20000] Hz
    f = f (f <= 20000);
    y = y (2:length(f), :);
    f = f (2:end);

    %magnitude
    mag = gainTodB(abs(y));

    mag = mag(2:length(mag), :);
    fmag = f(2:end);
    
    %reduced magnitude
    numChannels = size(mag)(2);
    magR = cell (1, numChannels);
    fmagR = cell (1, numChannels);

    for i = 1:numChannels
      [fmagR(1, i), magR(1, i)] = reducePlot(fmag, mag (:, i), 0.0001);
    endfor

    %plot magnitude    
    figure(fig, 'units', 'normalized', 'position', [0.1 0.1 0.8 0.8]);
    subplot(sp(1), sp(2), sp(3));

    hold on 
      set(gca,'xscale','log');
      set(gca, "linewidth", 1, "fontsize", 16);

      title('\fontsize{20}Magnitude Response');
      xlabel('\fontsize{16}frequency (Hz)');
      ylabel('\fontsize{16}magnitude (dB)');

      xlim([fmag(1), 20000]);
      ylim([-40, 6]);

      for i=1:numChannels
        plot (cell2mat(fmagR(i)), cell2mat(magR(i)), 'LineWidth', 1.5);
      endfor  
    hold off

    %phase
    p = angle(y);
    p = p (2:length(p), :);
    fp = fmag;

    %reduced phase
    pR = cell (1, numChannels);
    fpR = cell (1, numChannels);

    for i = 1:numChannels
      [fpR(1, i), pR(1, i)] = reducePlot(f, p(:, i), 0.0001);
    endfor

    %plot phase
    subplot(sp(1), sp(2), sp(3)+1);
    hold on
      set(gca,'xscale','log');
      set(gca, "linewidth", 1, "fontsize", 16);

      title(['\fontsize{20}Phase Response']);
      xlabel('\fontsize{16}frequency (Hz)');
      ylabel('\fontsize{16}phase (rad)');

      xlim([fp(1), 20000]);
      ylim([-pi, pi]);
      
      for i=1:numChannels
        plot (cell2mat(fmagR(i)), cell2mat(magR(i)), 'LineWidth', 1.5);
      endfor
    hold off
  endfunction

  function plotSpec(file, binary, ttl, fig, sp)
    %%  Plot a spectrogram of a file (max magnitude between all channels)

    [y, fs] = audioreadChecked(file);

    numChannelsOut = size(y)(2);

    if (strEq(fileparts(file)(2), 'SinSweep10'))
      dBDiff = gainTodB (max(max(y)) / 0.5); #input is normalized to 0.5
      printf("Estimated required makeup gain: %.1f dB.\n", -dBDiff);
    endif

    n = floor (1024 * (fs/44100));
    win = blackman(n);
    overlap = floor (8 * (fs/44100));

    %get max magnitude b/w all channels
    [S, f, t] = specgram (y(:,1), n, fs, win, overlap);
    S = abs(S);

    for i = 2:numChannelsOut
      [S1, ~, ~] = specgram (y(:, i), n, fs, win, overlap);
      S = max (S, abs(S1));
    endfor

    %normalize and convert to dB
    S = gainTodB(S/(max(max(S))));

    %Black and white binary image
    if (binary)
      S (S > -60) = 0;
    endif

    %clamp to [-60, 0dB]
    S (S < -60) = -60; 
    
    %plot
    figure(fig, 'units', 'normalized', 'position', [0.1 0.1 0.8 0.8]);
    subplot(sp(1), sp(2), sp(3));

    hold on
      set(gca, "fontsize", 16);

      title(['\fontsize{20}' ttl]);
      ylabel('\fontsize{16}frequency (Hz)');
      xlabel('\fontsize{16}time (s)');

      ylim([0, 20000]);
      xlim([0, audioinfo(file).Duration]);

      imagesc (t, f, S);
      colormap (1-gray);
    hold off
  endfunction

  function plotSignal(file, ttl, fig, sp)
    %% Plot a signal from an audio file

    [y, fs] = audioreadChecked(file);

    %t
    t = 0:1/fs:audioinfo(file).Duration-(1/fs);
    
    %reduced signal
    numChannels = size(y)(2);
    yR = cell (1, numChannels);
    tR = cell (1, numChannels);

    for i = 1:numChannels
      [tR(1, i), yR(1, i)] = reducePlot(t, y (:, i), 0.0001);
    endfor

    %plot
    figure(fig, 'units', 'normalized', 'position', [0.1 0.1 0.8 0.8]);
    subplot(sp(1), sp(2), sp(3));    

    hold on
      set(gca, "linewidth", 1, "fontsize", 16);

      title(['\fontsize{20}' ttl]);
      xlabel('\fontsize{16}t (s)');
      ylabel('\fontsize{16}amplitude');

      ylim ([-1, 1]);

      for i = 1:numChannels
        plot(cell2mat(tR(i)), cell2mat(yR(i)), 'LineWidth', 1.5);
      endfor 
    hold off
  endfunction

  function plotWaveshaper(file2, file1, dB, res, ttl, fig, sp)
    %% Plot samples of file2 vs file1
    %
    % Notes:
    % - 'dB': Set to true to make axes dB scale
    % - 'res': Set number of points to plot (decimate the signal); set to 0 to plot all points
    %%

    [x, ~] = audioread(file1);

    %dB/linear modes
    if (dB)
      [y, fs] = audioread(file2);
      y = gainTodB(y); 
      x = gainTodB(x); 
    else
      [y, fs] = audioreadChecked(file2);
    end

    numChannelsOut = size(y)(2);

    %downsample
    if (res>1)
      Q = floor(fs/res);
      last = length(x)-mod(length(x), Q);
      x = x(1:Q:last, :);
      y = y(1:Q:last, :);
    end

    %plot
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

      for i = 1:2:numChannelsOut
        scatter(x(:, 1), y(:, i), 1, 'filled');
        scatter(x(:, 2), y(:, i+1), 1, 'filled');
      endfor
    hold off
  endfunction

  function plotVectorscope(file, ttl, fig, sp)
    % Plot a vector scope from a stereo file 
      % See: https://www.rtw.com/en/blog/focus-the-vectorscope.html
    
    [y, fs] = audioreadChecked(file);
    numChannelsOut = size(y)(2);
  
    %normalize
    y = y/max(max(y)); 

    %plot
    figure(fig, 'units', 'normalized', 'position', [0.1 0.1 0.8 0.8]);
    subplot(sp(1), sp(2), sp(3));
    
    hold on;
      set(gca, "linewidth", 1, "fontsize", 16)

      title(['\fontsize{20}' ttl]);
      xlabel('\fontsize{16}R');
      ylabel('\fontsize{16}L');

      xlim([-1, 1]);
      ylim([-1, 1]);

      [counts, centers] = hist3 (y (:, 1:2));
      [r, l] = meshgrid (centers{1}, centers{2});
      nonzeroIdx = (counts > 0);
      scatter (r (nonzeroIdx), l (nonzeroIdx), 1, 'filled');
      for i = 3:2:numChannelsOut
        [counts, ~] = hist3 (y (:, i:i+1));
        nonzeroIdx = (counts > 0);
        scatter (r (nonzeroIdx), l (nonzeroIdx), 1, 'filled');
      endfor

      camroll (45);
    hold off 
  endfunction

%%==============================================================================
%% Utility

  function y = getPlugTime(plug)
    [plugDir, plugName, plugExt] = fileparts(plug); 

    y = getFileTime (plug);

    if (strEq ('.soulpatch', plugExt))
      plugSource = fromJSON(fileread(plug), false).soulPatchV1.source;
  
      if (iscell (plugSource))
        for i = 1:numel(plugSource)
          y = max (y, getFileTime ([plugDir '/' char(plugSource(i))]));
        endfor
      else 
        y = max (y, getFileTime ([plugDir '/' plugSource]));
      endif
      
    endif  
  endfunction

  function y = getFileTime (file)
    y = stat(file)(1).mtime;
  endfunction

  function [y, fs] = audioreadChecked(file)

    [y, fs] = audioread(file);
    
    if (any(abs(y) > 0.99))
      error ("%s is unstable or increases peak level to clipping.\n", file);
    endif

    if (max(y) < 0.01)
      warning ("%s is very quite or slient.\n", file);
    endif 
  endfunction

  function systemChecked (command)
    if (system (command)(1) ~= 0)
      error ('If testing a Non-SOUL plugin, make sure all controls/parameters are defined and 2-2 channel IO is supported.');
    endif
  endfunction

  function render (wavIn, wavOut)
    if (strEq (RENDER_CMD, 'soul render'))
      systemChecked ([RENDER_CMD ' ' PLUG ' --input=' wavIn ' --output=' wavOut ' --rate=' num2str(audioinfo(wavIn).SampleRate) ' --bitdepth=' num2str(audioinfo(wavIn).BitsPerSample)]); 
    else
      systemChecked ([RENDER_CMD ' ' PLUG ' ' wavIn ' ' wavOut]);
    endif
  endfunction

  function y = anyStrsEq (strs, target)

    if (~iscell(strs))
      error('strs must be a cell array');
    endif

    if (~ischar(target))
      error('target must be a char array');
    endif

    y = false;

    for i=1:numel(strs)
      if (strEq (char (strs(i)), target))
        y = true;
        return;
      endif
    endfor
  endfunction

  function y = strEq (str1, str2)
    if (length(str1) ~= length(str2))
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
