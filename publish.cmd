@echo off
set PROGDIR=%~dp0
rem Remove trailing backslash
set PROGDIR=%PROGDIR:~0,-1%
set OUTPUT=%~dpn1
set "PLANTUML=%PROGDIR%\filters\plantuml.jar"
set "TEXINPUTS=.;%PROGDIR%\templates;"
pandoc "--data-dir=%PROGDIR%" --defaults md2pdf -o "%OUTPUT%.pdf" "%~1"
pandoc "--data-dir=%PROGDIR%" --defaults md2html --self-contained -o "%OUTPUT%.html" "%~1"
