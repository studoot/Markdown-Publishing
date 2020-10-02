@echo off
@REM Don't want to leak variables out of this script
setlocal

@REM Get the script's directory and remove the trailing backslash...
set PROGDIR=%~dp0
set PROGDIR=%PROGDIR:~0,-1%

@REM Set variables for script adjacent locations
set "PLANTUML=%PROGDIR%\filters\plantuml.jar"
set "TEXINPUTS=.;%PROGDIR%\templates;"

@REM If no parameters, error exit.
if "%~1" EQU "" GOTO :NOARG

:DODOC

@REM Is the parameter a file?
if not exist "%~f1" (
    echo Parameter %1 is not a valid file path.
    goto :nextarg
)

@REM Get the input file's directory and remove the trailing backslash...
set DOCDIR=%~dp1
set DOCDIR=%DOCDIR:~0,-1%

@REM Default DOCDATE to the current date. This palaver is needed because CMD
@REM only shows locale formatted dates, and we want to reformat as ISO 8601.
@REM Why use %%G as the first loop variable? See https://ss64.com/nt/for.html
@REM for all the ugly detail... Also - we need to only extract one (of many)
@REM lines of output - there are loads of spurious blank lines...
for /f "delims=,= tokens=1-2" %%G in ('wmic os get LocalDateTime /value') do (
    if "%%~G" == "LocalDateTime" (
        set LocalDateTime=%%H
    )
)
@REM Extract date components and set DOCDATE.
set year=%LocalDateTime:~0,4%
set month=%LocalDateTime:~4,2%
set day=%LocalDateTime:~6,2%
set DOCDATE="--variable=date:%year%-%month%-%day%"

@REM Try and retrieve HEAD commit date from Git. Escaping special characters
@REM in the Git command is ***REQUIRED***.
for /f %%G in ('git -C ^"%DOCDIR%^" log -1 --date=short --format^=%%cd 2^>nul') do set DOCDATE="--variable=date:%%G"
    
@REM Try and retrieve HEAD commit ID
for /f "usebackq" %%G in (`git -C "%DOCDIR%" rev-parse --short HEAD 2^>nul`) do set COMMIT="--variable=commit:%%G"

@REM Get path of input file without the extension as the output name
set OUTPUT=%~dpn1

@REM Do the document conversions
pandoc "--data-dir=%PROGDIR%" --defaults md2pdf -o "%OUTPUT%.pdf" %DOCDATE% %COMMIT% "%~1"
pandoc "--data-dir=%PROGDIR%" --defaults md2html --self-contained -o "%OUTPUT%.html" %DOCDATE% %COMMIT% "%~1"

@REM Try the next parameter
:nextarg
shift
if "%~1" NEQ "" GOTO :DODOC

@REM Done.
endlocal
goto :eof

:NOARG
echo "Need to specify at least one Markdown file"
endlocal
goto :eof