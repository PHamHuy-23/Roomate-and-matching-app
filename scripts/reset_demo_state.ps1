<#
.SYNOPSIS
    Khôi phục nhanh dữ liệu hệ thống về trạng thái sạch phục vụ Demo (Rollback Clean State).
.DESCRIPTION
    Script chạy lại 01_schema.sql và 02_seed_data.sql trên Supabase.
#>

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$schemaFile = Join-Path $projectRoot "database\01_schema.sql"
$seedFile = Join-Path $projectRoot "database\02_seed_data.sql"
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

Write-Host "==========================================================" -ForegroundColor Magenta
Write-Host " RESET DATABASE VỀ TRẠNG THÁI DEMO SẠCH (SEED DATA)" -ForegroundColor Magenta
Write-Host "==========================================================" -ForegroundColor Magenta

$env:PGPASSWORD = $dbPass

if ($dbUrl -match "jdbc:postgresql://([^:/]+)(?::(\d+))?/([^?]+)") {
    $hostName = $matches[1]
    $port = if ($matches[2]) { $matches[2] } else { "5432" }
    $dbName = $matches[3]

    try {
        Write-Host "1. Nạp lại cấu trúc Schema (01_schema.sql)..."
        & psql -h $hostName -p $port -U $dbUser -d $dbName -f $schemaFile
        
        Write-Host "2. Nạp dữ liệu mẫu chuẩn (02_seed_data.sql)..."
        & psql -h $hostName -p $port -U $dbUser -d $dbName -f $seedFile

        Write-Host " ĐÃ KHÔI PHỤC TOÀN BỘ DỮ LIỆU DEMO VỀ TRẠNG THÁI BAN ĐẦU THÀNH CÔNG!" -ForegroundColor Green
    } catch {
        Write-Error "Lỗi khi thực hiện reset demo: $_"
    }
}
