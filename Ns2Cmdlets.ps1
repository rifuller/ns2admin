function NS2-InstallPrerequisites {
   param(
    [string]$DllDownloadBase = "https://github.com/rifuller/ns2admin/raw/master/dlls/",
    [string]$TempWorkingDir = "C:/temp/",
    [string]$WindowsDir = "C:/windows/"
   )
    $MicrosoftSigningThumbprint = "A4341B9FD50FB9964283220A36A1EF6F6FAA7840"
    $MicrosoftSigningThumbprint2 = "711AF71DC4C4952C8ED65BB4BA06826ED3922A32"
    $NvidiaSigningThumbprint = "C70111241901F5C3BCC2B19BDE110728A505912F"
    
    Write-Host -ForegroundColor "Green" "Installing Prerequisites..."

    DownloadFileAndVerify "http://us.download.nvidia.com/Windows/9.19.0218/PhysX-9.19.0218-SystemSoftware.exe" ($TempWorkingDir + "PhysX-9.19.0218-SystemSoftware.exe") $NvidiaSigningThumbprint
    # PhysX-9.19.0218-SystemSoftware.exe

    DownloadFileAndVerify "https://aka.ms/vs/16/release/vc_redist.x64.exe" ($TempWorkingDir + "vc_redist.x64.exe") $MicrosoftSigningThumbprint2
    # "vc_redist.x64.exe"

    DownloadFileAndVerify ($DllDownloadBase + "SysWOW64/msacm32.dll") ($WindowsDir + "SysWOW64/msacm32.dll") $MicrosoftSigningThumbprint
    DownloadFileAndVerify ($DllDownloadBase + "SysWOW64/avifil32.dll") ($WindowsDir + "SysWOW64/avifil32.dll") $MicrosoftSigningThumbprint
    DownloadFileAndVerify ($DllDownloadBase + "SysWOW64/msvfw32.dll") ($WindowsDir + "SysWOW64/msvfw32.dll") $MicrosoftSigningThumbprint
    DownloadFileAndVerify ($DllDownloadBase + "System32/msacm32.dll") ($WindowsDir + "System32/msacm32.dll") $MicrosoftSigningThumbprint
    DownloadFileAndVerify ($DllDownloadBase + "System32/avifil32.dll") ($WindowsDir + "System32/avifil32.dll") $MicrosoftSigningThumbprint
    DownloadFileAndVerify ($DllDownloadBase + "System32/msvfw32.dll") ($WindowsDir + "System32/msvfw32.dll") $MicrosoftSigningThumbprint

    Write-Host -ForegroundColor "Green" "Done."
}

function DownloadFileAndVerify($url, $outfile, $certthumbprint) {
    Write-Host "Downloading $url to $outfile"

    Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $outfile

    if (-not (Test-Path $outfile)) {
        throw "File didn't download."
    }

    $sig = Get-AuthenticodeSignature $outfile

    if ($sig.Status -ne "Valid") {
        throw "File downloaded does not have a valid digital signature: $url"
    }

    if ($sig.SignerCertificate.Thumbprint -ne $certthumbprint) {
        throw ("File downloaded was signed but not using the expected certificate. File = " + $outfile +"; Cert=" + $sig.SignerCertificate.Thumbprint  + "; Expected=" + $certthumbprint)
    }
}

function NS2-InstallSteamCmd {
    param (
        [parameter(Mandatory=$true)][string]$Username,
        [parameter(Mandatory=$true)][String]$Password,
        $OutPath = "C:\steamcmd"
    )

    Invoke-WebRequest -Uri http://media.steampowered.com/installer/steamcmd.zip -UseBasicParsing -OutFile steamcmd.zip
    Expand-Archive .\steamcmd.zip
    #mv .\steamcmd\ ..
}

function NS2-UpdateFirewallRules {
    param(
        $NS2Root = "C:\ns2server",
        $port = 27015
    )

    netsh advfirewall firewall add rule name="ns2server" dir=in action=allow program="C:\ns2server\x64\server.exe" enable=yes
    netsh advfirewall firewall add rule name="Open port 27015" dir=in action=allow protocol=TCP localport=27015
    netsh advfirewall firewall add rule name="Open port 27015 UDP" dir=in action=allow protocol=UDP localport=27015
    netsh advfirewall firewall add rule name="Open port 27016" dir=in action=allow protocol=TCP localport=27016
    netsh advfirewall firewall add rule name="Open port 27016 UDP" dir=in action=allow protocol=UDP localport=27016
}



