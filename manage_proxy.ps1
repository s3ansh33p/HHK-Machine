param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("enable", "disable", "install", "uninstall")]
    [string]$Action
)

$proxyAddress = "127.0.0.1:8080"
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Output "Restarting script as administrator..."
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args" -Verb RunAs
    exit
}

if ($Action -eq "enable") {
    Write-Output "Enabling proxy at $proxyAddress..."
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $regPath -Name ProxyServer -Value $proxyAddress
    netsh winhttp set proxy $proxyAddress | Out-Null
    Write-Output "Proxy enabled."
}
elseif ($Action -eq "disable") {
    Write-Output "Disabling proxy..."
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 0
    netsh winhttp reset proxy | Out-Null
    Write-Output "Proxy disabled."
}
elseif ($Action -eq "install") {
    Write-Output "Installing mitmproxy..."

    # Download the latest mitmproxy Windows installer (EXE)
    $mitmproxyUrl = "https://downloads.mitmproxy.org/12.1.1/mitmproxy-12.1.1-windows-x86_64-installer.exe"
    $installer = Join-Path $env:TEMP "mitmproxy-installer.exe"

    # Download mitmproxy installer
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0")
    $wc.DownloadFile($mitmproxyUrl, $installer)

    # Run the installer silently
    Write-Output "Running mitmproxy installer..."
    Start-Process $installer -ArgumentList "--mode unattended" -Wait

    # Remove installer
    Remove-Item -Path $installer -Force

    Write-Output "mitmproxy installed successfully."

    # Use the run.ps1 script to generate the certificate
    $runScript = 'C:\Program Files\mitmproxy\run.ps1'
    if (-Not (Test-Path $runScript)) {
        $runScript = 'C:\Program Files (x86)\mitmproxy\run.ps1'
    }

    if (Test-Path $runScript) {
        Write-Output "Generating mitmproxy certificate using run.ps1..."
        # Start mitmproxy in a new PowerShell process
        Start-Process -FilePath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
            -ArgumentList "-File `"$runScript`" mitmproxy" -PassThru

        # Wait for 5 seconds to allow the certificate to be generated
        Start-Sleep -Seconds 10

        # Attempt to stop the process by name
        try {
            Stop-Process -Name "mitmproxy" -Force -ErrorAction Stop
            Write-Output "mitmproxy process stopped."
        } catch {
            Write-Output "Failed to stop mitmproxy process: $($_.Exception.Message)"
        }

        $certPath = Join-Path $env:USERPROFILE ".mitmproxy\mitmproxy-ca-cert.pem"
        if (Test-Path $certPath) {
            Write-Output "Importing mitmproxy certificate to Windows Root store using certutil..."
            Start-Process -FilePath "certutil" -ArgumentList "-addstore", "root", "`"$certPath`"" -NoNewWindow -Wait
            Write-Output "mitmproxy certificate installed to Root store."
        } else {
            Write-Output "mitmproxy certificate not found at $certPath"
        }
    } else {
        Write-Output "run.ps1 not found, cannot generate or install certificate."
    }
}
elseif ($Action -eq "uninstall") {
    Write-Output "Uninstalling mitmproxy..."

    # Uninstall mitmproxy (silent)
    $uninstaller = 'C:\Program Files\mitmproxy\uninstall.exe'
    if (-Not (Test-Path $uninstaller)) {
        $uninstaller = 'C:\Program Files (x86)\mitmproxy\uninstall.exe'
    }
    if (Test-Path $uninstaller) {
        Write-Output "Running mitmproxy uninstaller..."
        Start-Process -FilePath $uninstaller -ArgumentList "--mode unattended" -Wait
        Write-Output "mitmproxy uninstalled."
    } else {
        Write-Output "mitmproxy uninstaller not found, skipping."
    }

    # Remove mitmproxy certificates from CurrentUser Root store using certutil
    Write-Output "Removing mitmproxy certificates from Root store using certutil..."
    $certs = certutil -store root | ForEach-Object {
        if ($_ -match "Issuer:.*mitmproxy") {
            $hashLine = $previousLine
            $hashLine -match "Serial Number:\s+([a-fA-F0-9]+)"
            $matches[1]
        }
        $previousLine = $_
    } | Where-Object { $_ -and $_ -ne $null -and $_ -ne "True" }

    foreach ($thumbprint in $certs) {
        try {
            Write-Output "Removing certificate with thumbprint: $thumbprint"
            Start-Process -FilePath "certutil" -ArgumentList "-delstore", "root", $thumbprint -NoNewWindow -Wait
        } catch {
            Write-Output "Failed to remove certificate with thumbprint: $thumbprint - $($_.Exception.Message)"
        }
    }

    # Delete .mitmproxy directory
    $mitmDir = Join-Path $env:USERPROFILE ".mitmproxy"
    if (Test-Path $mitmDir) {
        Remove-Item -Path $mitmDir -Recurse -Force
        Write-Output "Deleted $mitmDir"
    } else {
        Write-Output "$mitmDir not found."
    }

    Write-Output "Uninstall complete."
}