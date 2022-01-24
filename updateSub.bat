@echo off

REM This script initializes/updates all submodules

git submodule foreach git pull origin master
git submodule foreach git submodule update --init --recursive

octave qaClear.m