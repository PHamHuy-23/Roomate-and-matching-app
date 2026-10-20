<#
.SYNOPSIS
    Khôi phục cơ sở dữ liệu Supabase từ file sao lưu (.sql).
.DESCRIPTION
    Script sử dụng psql để nạp lại dữ liệu từ file backup đã lưu.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$BackupFile
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BackupFile)) {
    Write-Error "File backup không tồn tại: $BackupFile"
    exit 1
}

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
    Write-Error "Không tìm thấy biến DB_URL trong backend/.env."
    exit 1
}

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host " ĐANG TIẾN HÀNH KHÔI PHỤC DỮ LIỆU TỪ: $BackupFile" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

$env:PGPASSWORD = $dbPass

if ($dbUrl -match "jdbc:postgresql://([^:/]+)(?::(\d+))?/([^?]+)") {
    $hostName = $matches[1]
    $port = if ($matches[2]) { $matches[2] } else { "5432" }
    $dbName = $matches[3]

    try {
        & psql -h $hostName -p $port -U $dbUser -d $dbName -f $BackupFile
        if ($LASTEXITCODE -eq 0) {
            Write-Host " KHÔI PHỤC DỮ LIỆU HOÀN TẤT THÀNH CÔNG!" -ForegroundColor Green
        } else {
            Write-Error "psql thất bại với mã lỗi $LASTEXITCODE"
        }
    } catch {
        Write-Error "Lỗi khi chạy psql: $_"
    }
}
