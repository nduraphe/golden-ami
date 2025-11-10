Write-Host "Starting software installation..."

# Create temp dir
New-Item -ItemType Directory -Force -Path "C:\Temp"

# Download VSCode installer from S3
aws s3 cp s3://golden-ami-softwares-nagesh/VSCodeUserSetup-x64-1.93.1.exe C:\Temp\VSCodeUserSetup-x64-1.93.1.exe

# Install VSCode silently
Start-Process -FilePath "C:\Temp\VSCodeUserSetup-x64-1.93.1.exe" -ArgumentList "/silent","/mergetasks=!runcode" -Wait

Write-Host "VSCode installation completed!"