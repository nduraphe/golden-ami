<powershell>
# Enable WinRM service and listener
Set-Service -Name winrm -StartupType Automatic
Start-Service winrm

# Configure WinRM to listen on all addresses over HTTP
winrm quickconfig -q
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# Allow local admin to authenticate remotely
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
  -Name "LocalAccountTokenFilterPolicy" -Value 1 -Force

# Open the firewall for WinRM
netsh advfirewall firewall set rule group="Windows Remote Management" new enable=yes
netsh advfirewall firewall add rule name="WinRM Public HTTP" dir=in action=allow protocol=TCP localport=5985

Write-Host "✅ WinRM setup complete."
</powershell>