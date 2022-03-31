%Script version of qaFunc

qaClear;
Plug = argv (){1};

%Test @ 44.1 kHz
qaFunc (Plug, 44100);
mkdir ('results/signals44.1/');
movefile ('results/signals*.png/', 'results/signals44.1/', 'f');
close all force

% Add more sampling rates like this 
%
% %Test @ 192 kHz
% qaFunc (Plug, 192000);
% mkdir ('results/signals192/');
% movefile ('results/signals*.png/', 'results/signals192/', 'f');
% close all force