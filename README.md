Cross-platform way to run python in virtual environment, written in POSIX Shell with Batch Script declarations. Pystart combines env, venv and sudo, see the script header for details.

## Get with Python

```shell
python -c "import os, urllib.request; urllib.request.urlretrieve('https://raw.githubusercontent.com/sixxkai/pystart/master/pystart.bat', 'pystart.bat'); os.name == 'posix' and os.chmod('pystart.bat', 0o755)"
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

## Run as root

**Unix-like**
```shell
PYTHONVERBRUNAS=true ./pystart.bat script.py
```

**Windows**
```batch
cmd /c "set PYTHONVERBRUNAS=true & pystart.bat script.py"
```
