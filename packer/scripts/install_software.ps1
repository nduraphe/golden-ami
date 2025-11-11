Write-Host "Starting software installation..."

# Create temp dir
$TempDir = "C:\Temp"
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Force -Path $TempDir }

# Install AWS CLI v2 if not present
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "AWS CLI not found. Installing AWS CLI v2..."
    $AwsInstaller = Join-Path $TempDir "AWSCLIV2.msi"
    Invoke-WebRequest "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile $AwsInstaller
    Start-Process msiexec.exe -ArgumentList "/i",$AwsInstaller,"/qn" -Wait
    Write-Host "AWS CLI installation completed!"
} else {
    Write-Host "AWS CLI is already installed."
}

# Verify AWS CLI version
aws --version

# S3 bucket containing software installers
$BucketName = "golden-ami-softwares-nagesh"
Write-Host "Fetching software list from S3 bucket: $BucketName"

# List all .exe and .msi files in the bucket
$SoftwareList = aws s3 ls "s3://$BucketName/" | ForEach-Object { ($_ -split '\s+')[-1] } | Where-Object { $_ -match '\.exe$|\.msi$' }

if ($SoftwareList.Count -eq 0) {
    Write-Host "No software files found in S3 bucket."
} else {
    foreach ($Software in $SoftwareList) {
        $InstallerPath = Join-Path $TempDir $Software
        Write-Host "Downloading $Software..."
        aws s3 cp "s3://$BucketName/$Software" $InstallerPath

        Write-Host "Installing $Software..."
        if ($InstallerPath -like "*.msi") {
            Start-Process msiexec.exe -ArgumentList "/i",$InstallerPath,"/qn" -Wait
        } else {
            Start-Process -FilePath $InstallerPath -ArgumentList "/silent","/verysilent","/norestart" -Wait
        }

        # Optional cleanup
        # Remove-Item $InstallerPath -Force
        Write-Host "$Software installation completed!"
    }
}

Write-Host "All software installations completed!"