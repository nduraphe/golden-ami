# Enable WinRM service
Write-Host "Configuring WinRM..."
Set-Service winrm -StartupType Automatic
Start-Service winrm

# Create or reconfigure the HTTP listener on port 5985
Write-Host "Creating WinRM listener..."
winrm delete winrm/config/Listener?Address=*+Transport=HTTP | Out-Null
winrm create winrm/config/Listener?Address=*+Transport=HTTP "@{Port='5985'}" | Out-Null

# Allow remote access for local admins
Write-Host "Configuring LocalAccountTokenFilterPolicy..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
  -Name "LocalAccountTokenFilterPolicy" -Value 1 -Force

# Configure firewall rules
Write-Host "Updating firewall rules for WinRM..."
netsh advfirewall firewall set rule group="Windows Remote Management" new enable=yes | Out-Null
netsh advfirewall firewall add rule name="WinRM Public HTTP" dir=in action=allow protocol=TCP localport=5985 | Out-Null

# Verify listener
Write-Host "WinRM configuration complete. Current listeners:"
winrm enumerate winrm/config/Listener