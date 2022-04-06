%Script version of qaFunc
%Usage: octave qa.m <plugin path>

qaClear;
Plug = argv (){1};

%Test @ 44.1 kHz
qaFunc (Plug, 44100);
mkdir ('results/signals44.1/');
movefile ('results/signals*.png/', 'results/signals44.1/', 'f');
close all force

%Test @ 48 kHz
qaFunc (Plug, 48000);
mkdir ('results/signals48/');
movefile ('results/signals*.png/', 'results/signals48/', 'f');
close all force

% Add more sampling rates like this 
%
% %Test @ 192 kHz
% qaFunc (Plug, 192000);
% mkdir ('results/signals192/');
% movefile ('results/signals*.png/', 'results/signals192/', 'f');
% close all force