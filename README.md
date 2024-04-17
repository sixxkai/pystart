Cross-platform way to run Python in virtual environment, written in POSIX Shell with Batch Script declarations. Pystart combines env, venv and sudo, see the script header for details. It was created as a loader for Crossgui based applications.

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
PYTHONPATH=C:\Users\sixxkai\Desktop\crossgui
# PYTHONPYCACHEPREFIX=/var/cache/python
# PYTHONUNBUFFERED=true
PYTHONWARNINGS=ignore
```

## Script selector

```python
import sys
import tempfile

# assign 'script'
...

if len(sys.argv) == 2 and tempfile.gettempdir() in sys.argv[1]:
    with open(sys.argv[1], "w", encoding="utf-8") as temp:
        temp.write(script)
    sys.exit()

# not called from pystart, do something else
...
```

## Run as root

**Unix-like**

```shell
PYTHONVERBRUNAS=true ./pystart.bat script.py
```

**Windows**

```batch
start "" cmd /c "set PYTHONVERBRUNAS=true & pystart.bat script.py"
```

Run `cmd` without `start` to hide the window.

**Python code**

```python
import os
import sys

def run_as_admin():
    if os.name == "posix":
        isAdmin = os.getuid() == 0
    else:
        import ctypes
        isAdmin = ctypes.windll.shell32.IsUserAnAdmin()

    if not isAdmin:
        sys.exit(126)

run_as_admin()
```
