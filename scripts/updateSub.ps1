# This script initializes/updates all submodules

$CallerDir = (Get-Item .).FullName

cd $PSScriptRoot/..

git submodule foreach git pull origin master
git submodule foreach git submodule update --init --recursive

octave qaClear.m

cd $CallerDir