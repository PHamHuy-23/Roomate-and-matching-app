<#
.SYNOPSIS
    Sao lưu cơ sở dữ liệu PostgreSQL / Supabase vào file nén (.sql).
.DESCRIPTION
    Script tự động đọc cấu hình kết nối từ backend/.env hoặc biến môi trường,
    sau đó thực thi lệnh pg_dump để xuất toàn bộ cấu trúc và dữ liệu.
#>

[CmdletBinding()]
param (
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$envFile = Join-Path $projectRoot "backend\.env"

if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $parts = $line.Split("=", 2)
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($key)) {
                [System.Environment]::SetEnvironmentVariable($key, $value, "Process")
            }
        }
    }
}

$dbUrl = $env:DB_URL
$dbUser = $env:DB_USERNAME
$dbPass = $env:DB_PASSWORD

if (-not $dbUrl) {
    Write-Error "Không tìm thấy biến DB_URL trong backend/.env hoặc môi trường."
    exit 1
}

$backupsDir = Join-Path $projectRoot "database\backups"
if (-not (Test-Path $backupsDir)) {
    New-Item -ItemType Directory -Path $backupsDir -Force | Out-Null
}

if (-not $OutputFile) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFile = Join-Path $backupsDir "supabase_backup_$timestamp.sql"
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " ĐANG TIẾN HÀNH SAO LƯU POSTGRESQL / SUPABASE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Đích đến: $OutputFile"

$env:PGPASSWORD = $dbPass

if ($dbUrl -match "jdbc:postgresql://([^:/]+)(?::(\d+))?/([^?]+)") {
    $hostName = $matches[1]
    $port = if ($matches[2]) { $matches[2] } else { "5432" }
    $dbName = $matches[3]

    Write-Host "Host: $hostName | Port: $port | User: $dbUser | DB: $dbName"
    
    try {
        & pg_dump -h $hostName -p $port -U $dbUser -d $dbName --clean --if-exists --no-owner --no-privileges -f $OutputFile
        if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputFile)) {
            $size = (Get-Item $OutputFile).Length / 1KB
            Write-Host " SAO LƯU THÀNH CÔNG!" -ForegroundColor Green
            Write-Host "Kích thước: $([math]::Round($size, 2)) KB" -ForegroundColor Green
        } else {
            Write-Error "pg_dump thất bại với mã lỗi $LASTEXITCODE"
        }
    } catch {
        Write-Warning "Không tìm thấy lệnh pg_dump trên máy hoặc kết nối thất bại: $_"
        Write-Host "LƯU Ý: Bạn có thể cài đặt PostgreSQL Client hoặc chạy qua Docker/GitHub Actions." -ForegroundColor Yellow
    }
} else {
    Write-Error "Định dạng DB_URL không hợp lệ: $dbUrl"
}
