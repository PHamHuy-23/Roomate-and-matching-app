@echo off
title Khoi dong MySQL Server
echo ====================================================
echo    DANG KHOI DONG MYSQL SERVER CHO DO AN
echo ====================================================
echo.

:: Chạy ngầm MySQL Server
start /B "" "G:\mysql-26.7.0-winx64\bin\mysqld.exe"

echo [Thanh cong] MySQL da duoc bat va dang chay ngam!
echo Ban co the mo MySQL Workbench de lam viec roi.
echo.
pause
