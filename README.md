Cross-platform way to run Python in virtual environment, written in POSIX Shell with Batch Script declarations. PyStart combines env, venv and sudo, see the script header for details.

## Another virtual environment manager?

On a working computer, the programmer configures the system for development needs. There is a wide range of different IDEs and tools available.

The distribution process involves packaging or containerizing the project into a special form that contains all the dependencies and settings. This relieves the user from additional configuration steps.

PyStart provides basic setup of the required environment and is intended for testing and minimalistic development of Python projects. It is a simple solution when the source code author has not packaged the program.

The utility does not contain thousands of lines, it is easy to edit to suit your needs. PyStart was created as a loader for PopGui based applications.

## Tested platforms

* Windows 8.1, 10
* OSX
* Linux
* FreeBSD

## Get with Python

```shell
python -c "import os, urllib.request; urllib.request.urlretrieve('https://raw.githubusercontent.com/sixxkai/pystart/master/pystart.bat', 'pystart.bat'); os.name == 'posix' and os.chmod('pystart.bat', 0o755)"
```

## Advanced folder structure

```
folder/script.py
__main__.py
.env
pystart.bat
requirements.txt
script.py
```

## Example .env

```env
PYTHONBINARYPATH="C:\Program Files\Python310\python.exe"
PYTHONDONTWRITEBYTECODE=true
PYTHONPATH=C:\Users\sixxkai\Desktop\popgui
# PYTHONPYCACHEPREFIX=/var/cache/python
# PYTHONUNBUFFERED=true
PYTHONWARNINGS=ignore
```

## Script selector \_\_main\_\_

```python
import sys

# assign 'script'
...

if len(sys.argv) == 2 and "pystart" in sys.argv[1]:
    with open(sys.argv[1], "w", encoding="utf-8") as selector:
        selector.write(script)
    sys.exit()

# not called from pystart, do something else
...
```

## Run as root

**Unix-like**

```shell
PYTHONVERBRUNAS=true ./pystart.bat script.py
```

PyStart is not supposed to be sourced.

**Windows**

```batch
start "" cmd /c "set PYTHONVERBRUNAS=true & pystart.bat script.py"
```

Run `cmd` without `start` to hide the window.

**Python code**

```python
import os

def run_as_admin():
    if os.name == "posix":
        isAdmin = os.getuid() == 0
    else:
        import ctypes
        isAdmin = ctypes.windll.shell32.IsUserAnAdmin()

    if not isAdmin:
        import sys
        sys.exit(126)

run_as_admin()
```
