Write-Output "Windows Server is launching..."
Set-Content -Path "C:\tmp\log.txt" -Value "Boot script executed at $(Get-Date)"

# [>] Setup Repositories
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
Set-PSRepository -Name 'PSGallery' -SourceLocation "https://www.powershellgallery.com/api/v2" -InstallationPolicy Trusted

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

function Install-MinGW {
  Write-Output "Installing MinGW..."
  $ProgressPreference = 'SilentlyContinue'

  $Download64 = "https://github.com/niXman/mingw-builds-binaries/releases/download/14.2.0-rt_v12-rev1/x86_64-14.2.0-release-posix-seh-ucrt-rt_v12-rev1.7z"
  $Download32 = "https://github.com/niXman/mingw-builds-binaries/releases/download/14.2.0-rt_v12-rev1/i686-14.2.0-release-posix-dwarf-ucrt-rt_v12-rev1.7z"

  Write-Output "Downloading mingw64..."
  Invoke-WebRequest "$Download64" -OutFile ".\amd64.7z"
  Write-Output "Extracting mingw64..."
  Expand-7Zip -ArchiveFileName "amd64.7z" -TargetPath ".\"
  Remove-Item -Path ".\amd64.7z" -Force

  Write-Output "Downloading mingw32..."
  Invoke-WebRequest "$Download32" -OutFile ".\i686.7z"
  Write-Output "Extracting mingw32..."
  Expand-7Zip -ArchiveFileName "i686.7z" -TargetPath ".\"
  Remove-Item -Path ".\i686.7z" -Force

  $ProgressPreference = 'Continue'

  $dest = "$env:APPDATA\mingw-dual"
  Write-Output "Writing to $dest"
  md -Force $dest | Out-Null
  Move-Item -Path ".\*" -Destination "$dest"

  Write-Output "Adding mingw64 to PATH..."
  Add-PathEntry -To "$dest\mingw64\bin"
  Write-Output "Adding mingw32 to PATH..."
  Add-PathEntry -To "$dest\mingw32\bin"
  Write-Output "Done!"
}

# [>] Install Git
Write-Output "Installing Git..."
Install-Module -Name Git -Force -Scope CurrentUser
Write-Output "Git installed successfully"

# [>] Install 7-Zip
Write-Output "Installing 7-Zip..."
Install-Module -Name 7Zip4PowerShell -Force -Scope CurrentUser
Write-Output "7-Zip installed successfully"

# [>] Install MinGW
$origin = (Get-Item .).FullName
$work = Join-Path $Env:Temp $(New-Guid)
New-Item -Type Directory -Path $work | Out-Null
try {
    cd "$work"
    Install-MinGW
} finally {
    cd "$origin"
    Remove-Item -LiteralPath "$work" -Force -Recurse
}

# [>] Install Resource Hacker
Write-Output "Installing Resource Hacker..."
$Download = "https://www.angusj.com/resourcehacker/reshacker_setup.exe"
Invoke-WebRequest "$Download" -OutFile ".\reshacker_setup.exe"
Start-Process ".\reshacker_setup.exe" -ArgumentList "/S" -Wait
Remove-Item -Path ".\reshacker_setup.exe" -Force
Write-Output "Resource Hacker installed successfully"

# [>] Clone Hollyhock-3
Write-Output "Cloning Hollyhock-3..."
git clone "https://github.com/ClasspadDev/hollyhock-3.git" "C:\hollyhock-3"
Write-Output "Hollyhock-3 cloned successfully"

# [>] Cleanup
Add-Content -Path "C:\tmp\log.txt" -Value "Boot script completed at $(Get-Date)"
