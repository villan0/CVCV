function ChangePassword($password) {
  $objUser = [ADSI]("WinNT://$($env:computername)/appveyor")
  $objUser.SetPassword($password)
  $objUser.CommitChanges()
}

function SleepIfBeforeClone() {
  if (!(Get-ItemProperty 'HKLM:\SOFTWARE\Appveyor\Build Agent\State' -Name GetSources -ErrorAction Ignore).GetSources -eq "true") {
  sleep 30
  }   
}

if((Test-Path variable:islinux) -and $isLinux) {
  Write-Warning "Script Ini Tidak Berfungsi Untuk Linux."
  return
}

# Mengubah Password User.
Set-LocalUser -Name "Administrator" -Password (ConvertTo-SecureString -AsPlainText "@NaufalCream12" -Force)

# Mengambil IP
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like 'ethernet*'}).IPAddress
$port = 3389

if (-not $nonat) {
    if($ip.StartsWith('172.24.')) {
        $port = 33800 + ($ip.split('.')[2] - 16) * 256 + $ip.split('.')[3]
    } elseif ($ip.StartsWith('192.168.') -or $ip.StartsWith('10.240.')) {
        # new environment - behind NAT
        $port = 33800 + ($ip.split('.')[2] - 0) * 256 + $ip.split('.')[3]
    } elseif ($ip.StartsWith('10.0.')) {
        $port = 33800 + ($ip.split('.')[2] - 0) * 256 + $ip.split('.')[3]
    }
}

# Mengambil External IP.
$ip = (New-Object Net.WebClient).DownloadString('https://www.appveyor.com/tools/my-ip.aspx').Trim()

# Mengaktifkan Akses RDP.
Enable-NetFirewallRule -DisplayName 'Remote Desktop - User Mode (TCP-in)'
Start-Service -Name audiosrv

Write-Host "  Untuk Mengubah Windows Version Ke Settings > Environment > Build worker image" -ForegroundColor White
Write-Host "  Visual Studio 2013/2015 = Windows Server 2012 R2" -ForegroundColor White
Write-Host "  Visual Studio 2017 = Windows Server 2016" -ForegroundColor White
Write-Host "  Visual Studio 2019 = Windows Server 2019" -ForegroundColor White
Write-Host "  RDP Aktif 1 Jam, Jika RDPnya Mati Silahkan Rebuild Lagi!" -ForegroundColor White
Write-Host "  IP: $ip`:$port" -ForegroundColor Gray
Write-Host "  Username: Administrator" -ForegroundColor Gray
if(-not $env:appveyor_rdp_password) {
    Write-Host "  Password: @NaufalCream12" -ForegroundColor Gray
}
Write-Host "Silahkan Login Ke RDP Anda!!"

if($blockRdp) {
    $path = "$($env:USERPROFILE)\Desktop\Delete me to continue build.txt"
    # Membuat "lock" File.
    Set-Content -Path $path -Value ''
    # Tunggu Sampai "lock" File Didelete Oleh Sistem.
    while(Test-Path $path) {
      Start-Sleep -Seconds 1
    }
    Write-Host "Build Lock File Telah Dihapus. Build Telah DiResume!"
}
