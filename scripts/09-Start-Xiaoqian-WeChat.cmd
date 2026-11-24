@echo off
echo Starting the retired Python server edition. Current Windows WeChat deployment: https://github.com/AnthonyZZH/xiaoqian-weixin
rem Xiaoqian WeChat control panel (server). Data lives outside the app folder.
set XQ_WECHAT_DATA_DIR=C:\xiaoqian\data\wechat
cd /d C:\xiaoqian\app\wechat
start "" "C:\xiaoqian\app\wechat\.venv\Scripts\pythonw.exe" -X utf8 app.py
