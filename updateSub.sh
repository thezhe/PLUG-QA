#!/bin/bash

# This script initializes/updates all submodules
git submodule foreach git pull origin master
git submodule foreach git submodule update --init --recursive
chmod +x ./SameWav/builds/SameWav.app
octave qaClear.m