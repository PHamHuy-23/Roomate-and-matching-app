@echo off
chcp 65001 >nul
title Roommate Hub - Backend Server

echo ===================================================
echo       ROOMMATE HUB - BACKEND SERVER LAUNCHER       
echo ===================================================
echo.

cd /d "%~dp0backend"

if not exist ".env" (
    echo [CANH BAO] Khong tim thay file .env trong thu muc backend!
    if exist ".env.example" (
        echo Dang sao chep .env.example sang .env...
        copy .env.example .env >nul
        echo [INFO] Da tao file .env tu .env.example. Vui long kiem tra lai thong tin database trong backend/.env!
        echo.
    )
)

echo Dang khoi dong Spring Boot Backend...
echo Server se chay tai: http://localhost:8080
echo.

call mvnw.cmd spring-boot:run

echo.
echo Server da dung lai.
pause
