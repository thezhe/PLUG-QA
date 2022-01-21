%Script to use qa via script for ci or automation

arg_list = argv ();

qa(arg_list{1}, str2num(arg_list{2}), str2num(arg_list{3}));