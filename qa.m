%Script version of qaFunc

Plug = argv (){1};
qaClear;

qaFunc (Plug, 44100);
mkdir ('results/signals44.1/');
movefile ('results/signals*.png/', 'results/signals44.1/', 'f');

qaFunc (Plug, 96000);
mkdir ('results/signals96/');
movefile ('results/signals*.png/', 'results/signals96/', 'f');