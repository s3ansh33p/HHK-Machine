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
  mkdir -Force $dest | Out-Null
  Move-Item -Path ".\*" -Destination "$dest"

  Write-Output "Adding mingw64 to PATH..."
  Add-PathEntry -To "$dest\mingw64\bin"
  Write-Output "Adding mingw32 to PATH..."
  Add-PathEntry -To "$dest\mingw32\bin"
}

# [>] Install Git
Write-Output "Installing Git for Windows..."
$gitInstaller = "$env:TEMP\Git-Setup.exe"
Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.49.0.windows.1/Git-2.49.0-64-bit.exe" -OutFile $gitInstaller
Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
Remove-Item $gitInstaller -Force
Write-Output "Git for Windows installed successfully"

# [>] Ensure Git is in PATH for this session
$gitPaths = @(
    "$env:ProgramFiles\Git\cmd",
    "$env:ProgramFiles\Git\bin",
    "$env:ProgramFiles(x86)\Git\cmd",
    "$env:ProgramFiles(x86)\Git\bin",
    "$env:LocalAppData\Programs\Git\cmd",
    "$env:LocalAppData\Programs\Git\bin"
)
foreach ($gitPath in $gitPaths) {
    if (Test-Path $gitPath) {
        $env:Path = "$gitPath;$env:Path"
        break
    }
}

# [>] Install 7-Zip
Write-Output "Installing 7-Zip..."
Install-Module -Name 7Zip4PowerShell -Force -Scope CurrentUser
Write-Output "7-Zip installed successfully"

# [>] Microsoft Visual C++ Redistributable
Write-Output "Installing Microsoft Visual C++ Redistributable..."
$Download = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
Invoke-WebRequest "$Download" -OutFile ".\vc_redist.x64.exe"
Start-Process ".\vc_redist.x64.exe" -ArgumentList "/install", "/quiet", "/norestart" -Wait
Remove-Item -Path ".\vc_redist.x64.exe" -Force
Write-Output "Microsoft Visual C++ Redistributable installed successfully"

# [>] Install MinGW
# $origin = (Get-Item .).FullName
# $work = Join-Path $Env:Temp $(New-Guid)
# New-Item -Type Directory -Path $work | Out-Null
# try {
#     Set-Location "$work"
#     Install-MinGW
# } finally {
#     Set-Location "$origin"
#     Remove-Item -LiteralPath "$work" -Force -Recurse
# }

# [>] Clone Hollyhock-3
Write-Output "Cloning Hollyhock-3..."
git clone "https://github.com/ClasspadDev/hollyhock-3.git" "C:\hollyhock-3"
Write-Output "Hollyhock-3 cloned successfully"

# [>] Cleanup
Add-Content -Path "C:\tmp\log.txt" -Value "Boot script completed at $(Get-Date)"
