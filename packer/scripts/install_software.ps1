Write-Host "Starting software installation..."

# Temp directory
$TempDir = "C:\Temp"
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Force -Path $TempDir }

# --- Step 1: Install AWS CLI if not found ---
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "AWS CLI not found. Installing AWS CLI v2..."
    
    $AwsInstaller = Join-Path $TempDir "AWSCLIV2.msi"
    
    if (!(Test-Path $AwsInstaller)) {
        Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile $AwsInstaller
    }

    Start-Process msiexec.exe -ArgumentList "/i `"$AwsInstaller`" /qn" -Wait
    $env:PATH += ";C:\Program Files\Amazon\AWSCLIV2\"
    Write-Host "AWS CLI installation completed!"
}

Write-Host "AWS CLI Version:"
aws --version

# --- Step 2: Install all software from S3 dynamically ---
$BucketName = "golden-ami-softwares-nagesh"

try {
    $SoftwareList = aws s3 ls "s3://$BucketName/" --recursive | ForEach-Object {
        ($_ -split '\s+')[-1]
    } | Where-Object { $_ -ne "" }
} catch {
    Write-Warning "Failed to list S3 bucket: $_"
    $SoftwareList = @()
}

if ($SoftwareList.Count -eq 0) {
    Write-Host "No software files found in S3 bucket."
} else {
    foreach ($Software in $SoftwareList) {
        $LocalPath = Join-Path $TempDir $Software
        Write-Host "Downloading $Software..."
        aws s3 cp "s3://$BucketName/$Software" $LocalPath

        Write-Host "Installing $Software..."
        switch -Regex ($Software.ToLower()) {
            ".*\.exe$" {
                Start-Process -FilePath $LocalPath -ArgumentList "/silent","/mergetasks=!runcode" -Wait
            }
            ".*\.msi$" {
                Start-Process msiexec.exe -ArgumentList "/i `"$LocalPath`" /qn" -Wait
            }
            default {
                Write-Warning "$Software has unknown extension. Skipping."
            }
        }

        # Automatically add installed program paths to PATH if exe exists in Program Files
        $ProgramDirs = @("C:\Program Files", "C:\Program Files (x86)")
        foreach ($Dir in $ProgramDirs) {
            Get-ChildItem -Path $Dir -Recurse -Filter *.exe -ErrorAction SilentlyContinue | ForEach-Object {
                $ExePath = Split-Path $_.FullName
                if (-not ($env:PATH -split ";" | Where-Object { $_ -eq $ExePath })) {
                    $env:PATH += ";$ExePath"
                }
            }
        }
    }
}

Write-Host "All software installations completed!"