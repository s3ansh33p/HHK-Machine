function Add-PathEntry {
  param (
    $To
  )
  $env:Path += ";$To"
  [Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$To",
    [EnvironmentVariableTarget]::User)
}

# [>] Install Winmerge
Write-Output "Installing Winmerge..."
$Download = "https://ixpeering.dl.sourceforge.net/project/winmerge/stable/2.16.46/WinMerge-2.16.46-x64-Setup.exe?viasf=1"
Invoke-WebRequest "$Download" -OutFile ".\WinMerge-2.16.46-x64-Setup.exe"
Start-Process ".\WinMerge-2.16.46-x64-Setup.exe" -ArgumentList "/VERYSILENT", "SUPPRESSMSGBOXES" -Wait
Remove-Item -Path ".\WinMerge-2.16.46-x64-Setup.exe" -Force
Write-Output "Winmerge installed successfully"

# [>] Install BusyBox
Write-Output "Installing BusyBox..."
$Download = "https://frippery.org/files/busybox/busybox.exe"
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3")
$wc.DownloadFile($Download, ".\busybox.exe")
$dest = "C:\bin"
Write-Output "Writing to $dest"
mkdir -Force $dest | Out-Null
Move-Item -Path ".\busybox.exe" -Destination "$dest"
Write-Output "Adding BusyBox to PATH..."
Add-PathEntry -To "$dest"
Write-Output "BusyBox installed successfully"

# [>] Install Sysinternals Suite
Write-Output "Installing Sysinternals Suite..."
$Download = "https://download.sysinternals.com/files/SysinternalsSuite.zip"
$tempZip = Join-Path $env:TEMP "SysinternalsSuite.zip"
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3")
$wc.DownloadFile($Download, $tempZip)
$dest = "C:\bin"
Write-Output "Writing to $dest"
mkdir -Force $dest | Out-Null
Expand-7Zip -ArchiveFileName $tempZip -TargetPath $dest
Remove-Item -Path $tempZip -Force
Write-Output "Adding Sysinternals Suite to PATH..."
Add-PathEntry -To $dest
Write-Output "Sysinternals Suite installed successfully"

# [>] Install Resource Hacker
Write-Output "Installing Resource Hacker..."
$Download = "https://www.angusj.com/resourcehacker/reshacker_setup.exe"
Invoke-WebRequest "$Download" -OutFile ".\reshacker_setup.exe"
Start-Process ".\reshacker_setup.exe" -ArgumentList "/VERYSILENT", "SUPPRESSMSGBOXES" -Wait
Remove-Item -Path ".\reshacker_setup.exe" -Force
Write-Output "Resource Hacker installed successfully"

# [>] Install Python (32 and 64)
Write-Output "Installing Python..."
$Download64 = "https://www.python.org/ftp/python/3.13.2/python-3.13.2-amd64.exe"
$Download32 = "https://www.python.org/ftp/python/3.13.2/python-3.13.2.exe"
Invoke-WebRequest "$Download64" -OutFile ".\python-3.13.2-amd64.exe"
Invoke-WebRequest "$Download32" -OutFile ".\python-3.13.2.exe"
Start-Process ".\python-3.13.2-amd64.exe" -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1" -Wait
Start-Process ".\python-3.13.2.exe" -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1" -Wait

$pythonPath = "C:\Program Files\Python313"
$python32Path = "C:\Program Files (x86)\Python313-32"

# [>] Rename python.exe to python32.exe for 32-bit installation
if (Test-Path "$python32Path\python.exe") {
    Rename-Item -Path "$python32Path\python.exe" -NewName "python32.exe"
}
Remove-Item -Path ".\python-3.13.2-amd64.exe" -Force
Remove-Item -Path ".\python-3.13.2.exe" -Force

Add-PathEntry -To "$pythonPath"
Add-PathEntry -To "$python32Path"

Write-Output "Python installed successfully"
