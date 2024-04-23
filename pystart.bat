: #   ______  __  __         ______   ______  ______   ______  ______
: #  /\  == \/\ \_\ \       /\  ___\ /\__  _\/\  __ \ /\  == \/\__  _\
: #  \ \  _-/\ \____ \   __ \ \___  \\/_/\ \/\ \  __ \\ \  __<\/_/\ \/  __
: #   \ \_\   \/\_____\ /\_\ \/\_____\  \ \_\ \ \_\ \_\\ \_\ \_\ \ \_\ /\_\
: #    \/_/    \/_____/ \/_/  \/_____/   \/_/  \/_/\/_/ \/_/ /_/  \/_/ \/_/
: #
: # Cross-platform way to run Python in virtual environment
: # Version: 2.4
: #
: # Usage:
: # pystart.bat script.py args
: # pystart.bat folder/script.py args
: #
: # Dependencies:
: #  1) Python3
: #   (win): standard installation
: #   (nix): python3, python3-pip, python3-venv
: #  2) System Utilities
: #   (win): -
: #   (mac): -
: #   (nix): coreutils, findutils, grep, sed, polkit
: #
: # This tool provides basic setup of the required environment and is intended
: # for Python projects distribution. Its code can be rewritten in any other
: # language, but you will still have to run the commands. So shell is an
: # assembler in this case, everything is native and simple.
: #
: # ------------------------------ Features ----------------------------------
: #
: # Creates a virtual environment based on optional requirements.txt, which is
: # located in the same folder. It is possible to create an empty venv.
: #
: # Loads environment variables from .env file if it exists. This can be used
: # to set interpreter options. To specify which version of the interpreter
: # should be used when creating the venv, set the PYTHONBINARYPATH.
: #
: # You can add script selector __main__.py which will write the script name
: # to the path passed as an argument. Then it will be possible to run without
: # explicitly specifying the name. Or __main__.py can be used as the default
: # script. In this case, writing name to file is not needed. Default script
: # cannot request root access, but the selected one can.
: #
: # Requests administrator rights if needed, Powershell is used in Windows,
: # AppleScript in OS X and Polkit in Linux and BSD. When executing a script,
: # interpreter has only two exit codes: 0 (success) and 1 (an exception was
: # raised). You can set the exit code manually with sys.exit. Use code 126 to
: # have pystart.bat restart script with admin rights: "sys.exit(126)". If you
: # know that a program needs elevated privileges to run, but don't want to
: # edit the source code, declare PYTHONVERBRUNAS before calling. This will
: # immediately run the script as administrator, skipping loading environment.
: # Also will --upgrade global interpreter and speed up the launch of --clear.
: #
: # Clear interpreter cache:
: # pystart.bat --clear
: #
: # Upgrade outdated requirements:
: # pystart.bat --upgrade
: #
: # Execute an arbitrary command:
: # pystart.bat --execute
: #
: # Feel free to rename this file. To run on Windows, .bat or .cmd extension
: # is required. At the same time, the .py extension is not required, which
: # allows scripts to be named as subcommands of the utility. When running
: # *.py programs, interrupts are ignored.
: #
: # -------------------------- Syntax reference ------------------------------
: #
: # Colon in batch means label declaration, in POSIX shell it is equivalent to
: # true. A feature of COMMAND.COM is that it skips labels that it cannot
: # jump to. Label becomes unusable if it contains special characters. Thus,
: # inside a batch script, you can add a shell line with ":;". Cross-platform
: # comment is added using ":;#" or ": #". The space or semicolon are
: # necessary because sh considers # to be part of a command name if it is not
: # the first character of an identifier.
: #
: # For batch code blocks, heredocs can be used. This redirection mechanism is
: # for passing multiple lines of input to a command or to comment out code.
: # Once again use the colon trick to ignore this line in batch. Put the
: # delimiting identifier in quotes so shell does not interpret its contents.
: # Identifier is also an unused batch label for closing line to be ignored.
: # In this way shell treats batch code as an unused string, and cmd
: # executes it.
: #
: # DOS uses carriage return and line feed "\r\n" as a line ending, which Unix
: # uses just line feed "\n". So in order for script to run you may need to
: # convert end of line sequences with unix2dos or a text editor. Although on
: # Windows 8.1 pystart.bat runs without error with unix-style line endings.
: #
: # --------------------------------------------------------------------------
: #           Copyright (C) 2023 Six Kai under BSD-3-Clause license
: # --------------------------------------------------------------------------

:<<"::Main"
    @echo off
    setlocal EnableExtensions EnableDelayedExpansion

    call :determine_codepage codepage
    chcp 65001 > nul

    set filepath=%~dp0
    set filename=%~nx0

    if not exist "%filepath%.pystart\" (
        mkdir "%filepath%.pystart"
        attrib +h "%filepath%.pystart"
    )

    if not defined PYTHONVERBRUNAS (
        if "%~x1"==".py" (
            if not defined _sigint_trap goto restart_without_ctrl_handler
        )

        if exist "%filepath%.env" (
            for /f "tokens=* eol=# usebackq" %%i in ("%filepath%.env") do set %%i
        )

        if not exist "%filepath%venv\" (
            echo | set /p dummy="First run, creating a virtual environment.."
            if defined PYTHONBINARYPATH (
                set PYTHONBINARYPATH=!PYTHONBINARYPATH:"=!
            )
            if exist "!PYTHONBINARYPATH!" (
                "!PYTHONBINARYPATH!" -m venv "%filepath%venv"
            ) else (
                py -3 -m venv "%filepath%venv"
            )
            call "%filepath%venv\Scripts\activate.bat"
            if exist "%filepath%requirements.txt" (
                pip -qq install --use-pep517 -r "%filepath%requirements.txt"
            )
            for /f %%i in ('copy /z "%~f0" nul') do set CR=%%i
            <nul set /p dummy=".!CR!                                            !CR!"
        ) else (
            call "%filepath%venv\Scripts\activate.bat"
        )
    )

    if "%~1"=="" (
        if exist "%filepath%__main__.py" (
            python "%filepath%__main__.py" "%filepath%.pystart\getscript.tmp"
            if exist "%filepath%.pystart\getscript.tmp" (
                set /p script=<"%filepath%.pystart\getscript.tmp"
                del "%filepath%.pystart\getscript.tmp"
                call %0 "%script%"
            )
        ) else (
            echo Specify the script to run
        )
    ) else (
        if not exist "%filepath%%~1" (
            for %%i in (-c --clear) do (
                if /i "%~1"=="%%i" goto clear
            )
            for %%i in (-u --upgrade) do (
                if /i "%~1"=="%%i" goto upgrade
            )
            for %%i in (-e --execute) do (
                if /i "%~1"=="%%i" goto execute
            )
            for %%i in (-h --help) do (
                if /i "%~1"=="%%i" goto help
            )
            goto script_not_found

            :clear
            for /d /r "%filepath%" %%d in (__pycache__) do (
                if exist "%%d" (
                    echo %%d
                    rd /s /q "%%d"
                )
            )
            goto exit

            :upgrade
            rd /s /q "%localappdata%\pip\cache\selfcheck\" 2>nul
            python -m pip install --upgrade pip
            if exist "%filepath%requirements.txt" (
                pip install --upgrade --use-pep517 -r "%filepath%requirements.txt"
            )
            goto exit

            :execute
            cd %filepath%
            set /p usrcmd="(venv) > "
            %usrcmd%
            goto exit

            :help
            echo Usage: %filename% [-h] [script [^<args^>]] [-c ^| -u ^| -e]
            echo;
            echo Python Virtual Environment Utility 2.4
            echo;
            echo Positional arguments:
            echo script           script path in the utility folder
            echo args             arguments of the script to run
            echo;
            echo Utility options ^(used when not running scripts^):
            echo -c, --clear      clear interpreter cache
            echo -u, --upgrade    upgrade outdated requirements
            echo -e, --execute    enter a command to execute
            goto exit

            :script_not_found
            echo No script named "%~1"
            goto exit
        ) else (
            set args=%*
            rem "call set" also can be used
            set args=!args:*%1=!
            if not "!args!"=="" (
                set args=!args:~1!
            )
            if not defined PYTHONVERBRUNAS (
                if not exist "%filepath%.pystart\pythonrc.py" (
                    echo import ctypes
                    echo import runpy
                    echo import sys
                    echo;
                    echo ctypes.windll.kernel32.SetConsoleCtrlHandler^(None, False^)
                    echo;
                    echo try:
                    echo     runpy.run_path^(sys.argv.pop^(1^), run_name="__main__"^)
                    echo except SystemExit:
                    echo     raise
                    echo except:
                    echo     import traceback
                    echo     traceback.print_exc^(-1^)
                ) > "%filepath%.pystart\pythonrc.py"
                python "%filepath%.pystart\pythonrc.py" "%filepath%%~1" !args!
                if not errorlevel 126 goto exit
            )
            if not exist "%filepath%.pystart\getadmin.ps1" (
                call :write_bom_bytes "%filepath%.pystart\getadmin.ps1"
                (
                    echo Add-Type -Language CSharp -TypeDefinition @^"
                    echo using System.Runtime.InteropServices;
                    echo public static class User32
                    echo {
                    echo     [DllImport^("user32.dll"^)]
                    echo     public static extern bool IsWindowVisible^(int hwnd^);
                    echo }
                    echo ^"@
                    echo;
                    echo $PPID = ^(Get-CimInstance -Class Win32_Process -Filter "ProcessId = '$PID'"^).ParentProcessId
                    echo if ^($env:_sigint_trap^) {
                    echo     $PPID = ^(Get-CimInstance -Class Win32_Process -Filter "ProcessId = '$PPID'"^).ParentProcessId
                    echo }
                    echo $proc = Get-Process -Id $PPID
                    echo;
                    echo If ^([User32]::IsWindowVisible^($proc.MainWindowHandle^)^) {
                    echo     Start-Process cmd -ArgumentList "/k",^"`"cd","/d",^"`"$($args[0])`"^","&","cls","&",^"`"$($args[1])`"^",^"`"$($args[2])`" $^($args[3]^)`"" -Verb RunAs
                    echo }
                    echo Else {
                    echo     Start-Process cmd -ArgumentList "/c",^"`"cd","/d",^"`"$($args[0])`"^","&",^"`"$($args[1])`"^",^"`"$($args[2])`" $^($args[3]^)`"" -Verb RunAs -WindowStyle hidden
                    echo }
                ) >> "%filepath%.pystart\getadmin.ps1"
                rem removing pythonrc.py and getadmin.ps1 fixes errors when updating pystart
            )
            rem powershell changes font if utf-8 code page is set
            chcp 437 > nul
            powershell -NoProfile -ExecutionPolicy bypass -File "%filepath%.pystart\getadmin.ps1" "%cd%" "%~f0" "%~1" "!args!" > nul 2>&1
        )
    )

    :exit
    rem implicit endlocal at EOF deactivates venv
    chcp %codepage% > nul
    exit /b
::Main

:<<"::Functions"
    :determine_codepage  rtnVar
    :: Determine current codepage, works in different languages.
    for /f "tokens=2 delims=:." %%i in ('chcp') do (
        set dummy=%%i
        set %~1=!dummy:~1!
    )
    exit /b

    :hexprint  string  [rtnVar]
    :: Based on built-in forfiles ability to include special characters
    :: in the command line, using hexadecimal code. Allows to generate a
    :: printable character for any byte code value except 0x00 (nul),
    :: 0x0A (newline), and 0x0D (carriage return).
    for /f tokens^=*^ delims^=^ eol^= %%i in (
        'forfiles /p "%~dp0." /m "%~nx0" /c "cmd /c echo;%~1"'
    ) do (
        if "%~2"=="" (
            echo;%%i
        ) else (
            set %~2=%%i
        )
    )
    exit /b

    :write_bom_bytes  filename
    :: Create file with UTF-8 BOM.
    :: Because powershell doesn't read unicode without it.
    call :determine_codepage CP
    chcp 437 > nul
    call :hexprint "0xEF" EF
    call :hexprint "0xBB" BB
    call :hexprint "0xBF" BF
    echo | set /p dummy="%EF%%BB%%BF%" > %1
    chcp %CP% > nul
    exit /b

    :restart_without_ctrl_handler
    :: Goto undefined label is a fatal error. It immediately terminates
    :: Batch processing. However, the currently executing block of code
    :: continues to completion using command line context.
    (
    goto undefined 2>nul
    title %comspec%
    set _sigint_trap=true
    start "" /b /wait cmd /c "%0 %*"
    set "_sigint_trap="
    chcp %codepage% > nul
    )
::Functions

filepath=$(readlink -f -- "$0")
filename=$(basename -- "$filepath")
filepath=$(dirname -- "$filepath")

if [ ! -d "$filepath/.pystart" ]; then
    mkdir "$filepath/.pystart"
fi

if [ -z "$PYTHONVERBRUNAS" ]; then
    if [ ".${1##*.}" = ".py" ]; then
        trap " " INT
    fi

    if [ -f "$filepath/.env" ]; then
        set -a; . "$filepath/.env"; set +a
    fi

    if [ ! -d "$filepath/venv" ]; then
        printf "First run, creating a virtual environment.."
        if [ -f "$PYTHONBINARYPATH" ]; then
            "$PYTHONBINARYPATH" -m venv "$filepath/venv"
        else
            python3 -m venv "$filepath/venv"
        fi
        . "$filepath/venv/bin/activate"
        if [ -f "$filepath/requirements.txt" ]; then
            pip -qq install --use-pep517 -r "$filepath/requirements.txt"
        fi
        printf ".\r\033[0K"
    else
        . "$filepath/venv/bin/activate"
    fi
fi

if [ -z "$1" ]; then
    if [ -f "$filepath/__main__.py" ]; then
        python "$filepath/__main__.py" "$filepath/.pystart/getscript.tmp"
        if [ -f "$filepath/.pystart/getscript.tmp" ]; then
            script=$(cat "$filepath/.pystart/getscript.tmp")
            rm "$filepath/.pystart/getscript.tmp"
            "$0" "$script"
        fi
    else
        echo Specify the script to run
    fi
elif [ ! -f "$filepath/$1" ]; then
    case $(echo $1 | tr "[:upper:]" "[:lower:]") in
        -c|--clear)
            find "$filepath" -type d -name __pycache__ -print -exec rm -rf {} \+
            ;;
        -u|--upgrade)
            if [ "$(uname)" = "Darwin" ]; then
                rm -rf "$HOME/Library/Caches/pip/selfcheck/"
            else
                rm -rf "$HOME/.cache/pip/selfcheck/"
            fi
            python -m pip install --upgrade pip
            if [ -f "$filepath/requirements.txt" ]; then
                pip install --upgrade --use-pep517 -r "$filepath/requirements.txt"
            fi
            ;;
        -e|--execute)
            pushd "$filepath" > /dev/null
            read -p "(venv) > " usrcmd
            eval $usrcmd
            popd > /dev/null
            ;;
        -h|--help)
            echo "Usage: $filename [-h] [script [<args>]] [-c | -u | -e]"
            echo
            echo Python Virtual Environment Utility 2.4
            echo
            echo Positional arguments:
            echo "script           script path in the utility folder"
            echo "args             arguments of the script to run"
            echo
            echo Utility options \(used when not running scripts\):
            echo "-c, --clear      clear interpreter cache"
            echo "-u, --upgrade    upgrade outdated requirements"
            echo "-e, --execute    enter a command to execute"
            ;;
        *)
            echo No script named "\"$1\""
            ;;
    esac
else
    script="$1"
    shift
    if [ -z "$PYTHONVERBRUNAS" ]; then
        python "$filepath/$script" "$@"
    else
        (exit 126)
    fi
    if [ $? -eq 126 ]; then
        if [ -t 0 ]; then
            if command -v sudo > /dev/null; then
                sudo "$filepath/$filename" "$script" $*
            else
                su -l root -c "'$filepath/$filename' '$script' $*"
            fi
        else
            if [ "$(uname)" = "Darwin" ]; then
                osascript -e "do shell script \"env -i '$filepath/$filename' '$script' $*\" with administrator privileges"
            else
                if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ] || [ -n "$MIR_SOCKET" ]; then
                    pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY "$filepath/$filename" "$script" "$@"
                else
                    echo "Can't run \"$script\" as root with redirected input"
                fi
            fi
        fi
    fi
fi

if [ -z "$PYTHONVERBRUNAS" ]; then
    if [ -f "$filepath/.env" ]; then
        unset $(grep -E -v "^#|^$" "$filepath/.env" | sed -E "s/(.*)=.*/\1/" | xargs)
    fi

    deactivate
fi
