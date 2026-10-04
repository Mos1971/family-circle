@echo off
cd /d "%~dp0"
"C:\flutter\bin\flutter.bat" run -d web-server --web-port 8942 --web-hostname 0.0.0.0 --dart-define=USE_MOCK=true
