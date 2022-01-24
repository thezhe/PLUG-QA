@echo off

REM This script initializes/updates all submodules

octave qaClear.m

git submodule foreach git pull origin master
git submodule foreach git submodule update --init --recursive