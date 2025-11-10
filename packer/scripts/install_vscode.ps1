Write-Host "Starting software installation..."

# Create temp dir
$TempDir = "C:\Temp"
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Force -Path $TempDir }

# Download VSCode installer from S3
$InstallerPath = Join-Path $TempDir "VSCodeUserSetup-x64-1.93.1.exe"
if (!(Test-Path $InstallerPath)) {
    aws s3 cp s3://golden-ami-softwares-nagesh/VSCodeUserSetup-x64-1.93.1.exe $InstallerPath
}

# Install VSCode silently
Start-Process -FilePath $InstallerPath -ArgumentList "/silent","/mergetasks=!runcode" -Wait

# Optional cleanup
# Remove-Item $InstallerPath -Force

Write-Host "VSCode installation completed!"