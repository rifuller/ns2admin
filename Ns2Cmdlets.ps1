function Invoke-InstallNS2Prerequisites {
    [CmdletBinding()]
    param(
        [string]
        $DllDownloadBase = "https://github.com/rifuller/ns2admin/raw/master/dlls/",

        [string]
        $TempDir,

        [string]
        $WindowsDir = "C:/Windows/"
    )
    $MicrosoftSigningThumbprint = "A4341B9FD50FB9964283220A36A1EF6F6FAA7840"
    $MicrosoftSigningThumbprint2 = "711AF71DC4C4952C8ED65BB4BA06826ED3922A32"
    $NvidiaSigningThumbprint = "C70111241901F5C3BCC2B19BDE110728A505912F"
        
    Invoke-DownloadVerifySignature `
        -Url "http://us.download.nvidia.com/Windows/9.19.0218/PhysX-9.19.0218-SystemSoftware.exe" `
        -TempDir $TempDir `
        -ExpectedSigningThumbprint $NvidiaSigningThumbprint `
        -Execute

    Invoke-DownloadVerifySignature `
        -Url "https://aka.ms/vs/16/release/vc_redist.x64.exe" `
        -TempDir $TempDir `
        -ExpectedSigningThumbprint $MicrosoftSigningThumbprint2 `
        -Execute

    $WindowsDlls = @("SysWOW64/msacm32.dll", "SysWOW64/avifil32.dll", "SysWOW64/msvfw32.dll", "System32/msacm32.dll", "System32/avifil32.dll", "System32/msvfw32.dll")
    foreach ($file in $WindowsDlls) {
        Invoke-DownloadVerifySignature `
        -Url ($DllDownloadBase + $file) `
        -TempDir $TempDir `
        -OutFile (Join-Path $WindowsDir $file) `
        -ExpectedSigningThumbprint $MicrosoftSigningThumbprint
    }
}

function Invoke-DownloadVerifySignature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Url,

        [Parameter(Mandatory=$true)]
        [string]
        $TempDir,

        [Parameter(Mandatory=$false)]
        [string]
        $OutFile,

        [Parameter(Mandatory=$true)]
        [string]
        $ExpectedSigningThumbprint,

        [switch]
        $ExpandArchive = $false,

        [Switch]
        $Execute = $false
    )

    # Check the temp dir exists
    if (-not (Test-Path $TempDir)) {
        New-Item -Path $TempDir -ItemType "directory"
    }

    $FileName = split-path -Leaf $Url
    $TempFile = Join-Path $TempDir $FileName
    $ExecuteFile = $TempFile

    Write-Host "Downloading $Url to $TempFile"

    Invoke-WebRequest -Uri $Url -UseBasicParsing -OutFile $TempFile

    if (-not (Test-Path $TempFile)) {
        throw "File didn't download."
    }

    # Expand the archive first if necessary. We're assuming it only contains a single file here until 
    # there's a need to implement otherwise. (This is only for steamcmd right now)
    if ($ExpandArchive) {
        Expand-Archive -Path $TempFile -DestinationPath .
        $TempFile = $TempFile.Substring(0, $b.LastIndexOf("."))
    }

    # Validate digital signature for the file
    $sig = Get-AuthenticodeSignature $TempFile

    if ($sig.Status -ne "Valid") {
        throw "File downloaded does not have a valid digital signature: $Url"
    }

    if ($sig.SignerCertificate.Thumbprint -ne $ExpectedSigningThumbprint) {
        throw ("File downloaded was signed but not using the expected certificate. File = " + $TempFile +"; Cert=" + $sig.SignerCertificate.Thumbprint  + "; Expected=" + $ExpectedSigningThumbprint)
    }

    # Valid digital signature - copy to the target directory
    if ($OutFile -ne "") {
        Write-Verbose "Copying to destination $OutFile"

        # this creates the intermediate directories first
        New-Item -ItemType File -Path $OutFile -Force | Out-Null
        Move-Item -Path $TempFile -Destination $OutFile -Force | Out-Null

        $ExecuteFile = $OutFile
    }

    # If execute
    if ($Execute) {
        Write-Verbose "Executing $ExecuteFile"
        Invoke-Expression "& $ExecuteFile /quiet /norestart"
    }
}

function Invoke-InstallSteamCmd {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $OutPath,

        [Parameter(Mandatory=$true)]
        [string]
        $Username,

        [Parameter(Mandatory=$true)]
        [securestring]
        $Password
    )

    $ValveSigningThumbprint = "cb84b870fab19be50acfd1663414488852b8934a"

    Invoke-DownloadVerifySignature `
        -Url "http://media.steampowered.com/installer/steamcmd.zip" `
        -TempDir $TempDir `
        -ExpectedSigningThumbprint $ValveSigningThumbprint `
        -OutFile (Join-Path $OutPath "steamcmd.exe")
        -ExpandArchive

    # Generate the NS2 install/update script
    
}

function NS2-UpdateFirewallRules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $NS2Root, 

        [Parameter(Mandatory=$true)]
        [Int] 
        $Port = 27015
    )

    $serverexe_path = Join-Path $NS2Root "x64/server.exe"

    if (-not (Test-Path $serverexe_path)) {
        throw "Could not find server.exe at path: $serverexe_path"
    }

    $Port2 = $Port + 1

    netsh advfirewall firewall add rule name="ns2server" dir=in action=allow program="$serverexe_path" enable=yes
    netsh advfirewall firewall add rule name="Open port $Port" dir=in action=allow protocol=TCP localport=$Port
    netsh advfirewall firewall add rule name="Open port $Port UDP" dir=in action=allow protocol=UDP localport=$Port
    netsh advfirewall firewall add rule name="Open port $Port2" dir=in action=allow protocol=TCP localport=$Port2
    netsh advfirewall firewall add rule name="Open port $Port2 UDP" dir=in action=allow protocol=UDP localport=$Port2
}

$TempDir = "C:/temp"
Write-Host -ForegroundColor "Green" "Installing system pre-requisites... " -NoNewline
Invoke-InstallNS2Prerequisites -TempDir $TempDir
Write-Host -ForegroundColor "Green" "done."

Write-Host -ForegroundColor "Green" "Installing steamcmd... " -NoNewline

Write-Host -ForegroundColor "Green" "done."
