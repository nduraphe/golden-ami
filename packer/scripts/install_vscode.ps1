Write-Host "Starting software installation..."

# Create temp dir
$TempDir = "C:\Temp"
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Force -Path $TempDir }

# ------------------------------
# Step 1: Install AWS CLI v2 if not installed
# ------------------------------
$AwsCliPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
if (!(Test-Path $AwsCliPath)) {
    Write-Host "AWS CLI not found. Installing AWS CLI v2..."
    $AwsInstaller = Join-Path $TempDir "AWSCLIV2.msi"
    
    # Download AWS CLI v2 MSI
    Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile $AwsInstaller

    # Install silently
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$AwsInstaller`"", "/qn" -Wait

    Write-Host "AWS CLI installation completed!"
} else {
    Write-Host "AWS CLI already installed."
}

# ------------------------------
# Step 2: List all software files from S3
# ------------------------------
$BucketName = "golden-ami-softwares-nagesh"
Write-Host "Fetching software list from S3 bucket: $BucketName"

$SoftwareFiles = & "$AwsCliPath" s3 ls "s3://$BucketName/" | ForEach-Object {
    ($_ -split "\s+")[-1]  # get the last column (file name)
}

if ($SoftwareFiles.Count -eq 0) {
    Write-Host "No software files found in S3 bucket."
    exit
}

# ------------------------------
# Step 3: Download and install each software
# ------------------------------
foreach ($file in $SoftwareFiles) {
    $InstallerPath = Join-Path $TempDir $file

    if (!(Test-Path $InstallerPath)) {
        Write-Host "Downloading $file from S3..."
        & "$AwsCliPath" s3 cp "s3://$BucketName/$file" $InstallerPath
    } else {
        Write-Host "$file already exists locally."
    }

    Write-Host "Installing $file..."

    # Detect installer type and run appropriate silent install
    switch -Wildcard ($InstallerPath) {
        "*.msi" {
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$InstallerPath`"", "/qn" -Wait
        }
        "*.exe" {
            Start-Process -FilePath $InstallerPath -ArgumentList "/silent","/verysilent","/norestart","/mergetasks=!runcode" -Wait
        }
        default {
            Write-Host "Unknown installer type for $file. Skipping..."
        }
    }
}

Write-Host "All software installation completed!"