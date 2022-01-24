% Script to clear all cached data generated from qa.m

% clear persistent variables
clear all;

% clear results
confirm_recursive_rmdir(0);
rmdir('results', 's');