# TIL: Get-Authenticode Signature can return different thumbprints based on environment. 
# Windows has a catalog of digital signatures for all of its assets and that will take
# preference over embedded digital signatures. It also means that files don't need embedded
# sigs either. This poses a problem when we move the DLL dependencies onto a diff machine
# and the catalog doesn't know them and they don't have embedded sigs - they are effectively
# unsigned.
# See: https://github.com/PowerShell/PowerShell/issues/8401#issuecomment-445396418

$TrustedPublisherThumbprints = @(
    "A4341B9FD50FB9964283220A36A1EF6F6FAA7840", # Microsoft Catalog
    "FF82BC38E1DA5E596DF374C53E3617F7EDA36B06", # Microsoft Authenticode
    "711AF71DC4C4952C8ED65BB4BA06826ED3922A32", # Other Microsoft one
    "C70111241901F5C3BCC2B19BDE110728A505912F", # NVidia
    "cb84b870fab19be50acfd1663414488852b8934a"  # Valve
)

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
        
    Invoke-DownloadVerifySignature `
        -Url "http://us.download.nvidia.com/Windows/9.19.0218/PhysX-9.19.0218-SystemSoftware.exe" `
        -TempDir $TempDir `
        -Execute

    Invoke-DownloadVerifySignature `
        -Url "https://aka.ms/vs/16/release/vc_redist.x64.exe" `
        -TempDir $TempDir `
        -Execute

    $WindowsDlls = @("SysWOW64/msacm32.dll", "SysWOW64/avifil32.dll", "SysWOW64/msvfw32.dll", "System32/msacm32.dll", "System32/avifil32.dll", "System32/msvfw32.dll")
    foreach ($file in $WindowsDlls) {
        # TOOD: Skip if the files already exist in the windows directory. These are really only needed for server core.
        Invoke-DownloadVerifySignature `
        -Url ($DllDownloadBase + $file) `
        -TempDir $TempDir `
        -OutFile (Join-Path $WindowsDir $file) `
        -BypassSignatureValidation
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

        [Switch]
        $SteamCmd = $false,

        [Switch]
        $Execute = $false,

        [Switch]
        $BypassSignatureValidation = $false
    )

    # Check the temp dir exists
    if (-not (Test-Path $TempDir)) {
        New-Item -Path $TempDir -ItemType "directory"
    }

    $FileName = split-path -Leaf $Url
    $TempFile = Join-Path $TempDir $FileName
    $ExecuteFile = $TempFile

    Write-Verbose "Downloading $Url to $TempFile"

    Invoke-WebRequest -Uri $Url -UseBasicParsing -OutFile $TempFile

    if (-not (Test-Path $TempFile)) {
        throw "File didn't download."
    }

    # Expand the archive first if necessary. We're assuming it only contains a single file here until 
    # there's a need to implement otherwise. (This is only for steamcmd right now)
    if ($SteamCmd) {
        Expand-Archive -Path $TempFile -Destination $TempDir -Force
        $TempFile = $TempFile.Substring(0, $TempFile.LastIndexOf(".")) + ".exe"
    }

    # Validate digital signature for the file
    if (-not $BypassSignatureValidation) {
        $sig = Get-AuthenticodeSignature $TempFile

        if ($sig.Status -ne "Valid") {
            throw "File downloaded does not have a valid digital signature: $TempFile"
        }
    
        if ($TrustedPublisherThumbprints -notcontains $sig.SignerCertificate.Thumbprint) {
            throw ("File downloaded was signed but not using a trusted certificate. File = " + $TempFile +"; Cert=" + $sig.SignerCertificate)
        }
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
        Invoke-Expression "& $ExecuteFile /q /quiet /norestart"
    }
}

function Invoke-InstallSteamCmd {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $OutPath
    )

    $TargetFile = (Join-Path $OutPath "steamcmd.exe")

    Invoke-DownloadVerifySignature `
        -Url "http://media.steampowered.com/installer/steamcmd.zip" `
        -TempDir $TempDir `
        -OutFile $TargetFile `
        -SteamCmd
}

function Invoke-InstallNS2 {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $SteamPath,

        [Parameter(Mandatory=$true)]
        [string]
        $Username,

        [Parameter(Mandatory=$true)]
        [securestring]
        $Password,

        [Parameter(Mandatory=$true)]
        [string]
        $NS2Path
    )

    # Generate the NS2 install/update script
    $SteamCMDPath = (Join-Path $SteamPath "steamcmd.exe")
    $UpdateNS2ScriptPath = (Join-Path $NS2Path "updatens2.cmd")
    $PlainTextPassword = ConvertFrom-SecureString -SecureString $Password -AsPlainText
    $content = "@echo off
    `"$SteamCMDPath`" +login `"$Username`" `"$PlainTextPassword`" +force_install_dir `"$NS2Path`" +app_update 4940 validate +quit"
    New-Item -Path $UpdateNS2ScriptPath -Value $content -Force | Out-Null

    Invoke-Expression "& $UpdateNS2ScriptPath"
}

function Set-NS2FirewallRules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $NS2Path, 

        [Parameter(Mandatory=$false)]
        [Int] 
        $Port = 27015
    )

    $ServerExePath = Join-Path $NS2Path "x64/server.exe"

    if (-not (Test-Path $ServerExePath)) {
        throw "Could not find server.exe at path: $ServerExePath"
    }

    $Port2 = $Port + 1

    netsh advfirewall firewall add rule name="ns2server" dir=in action=allow program="$ServerExePath" enable=yes
    netsh advfirewall firewall add rule name="Open port $Port" dir=in action=allow protocol=TCP localport=$Port
    netsh advfirewall firewall add rule name="Open port $Port UDP" dir=in action=allow protocol=UDP localport=$Port
    netsh advfirewall firewall add rule name="Open port $Port2" dir=in action=allow protocol=TCP localport=$Port2
    netsh advfirewall firewall add rule name="Open port $Port2 UDP" dir=in action=allow protocol=UDP localport=$Port2
}

$TempDir = "C:/temp"
$SteamDir = "C:/steamcmd"
$NS2Dir = "C:/NS2Server"

Write-Host
Write-Host -ForegroundColor Cyan "NS2 Onebox Script"
Write-Host -ForegroundColor Cyan "  Maintained by: idk"
Write-Host -ForegroundColor Cyan "  Source code: https://github.com/rifuller/ns2admin"
Write-Host

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Script must be run from an elevated command prompt."
}

Write-Host -NoNewLine "Enter steam username: " 
$Username = Read-Host

Write-Host -NoNewLine "Enter steam password: " 
$Password = Read-Host -AsSecureString

Write-Host -ForegroundColor "Green" "Installing system pre-requisites... " -NoNewline
Invoke-InstallNS2Prerequisites -TempDir $TempDir -WindowsDir "C:/temp_windows"
Write-Host -ForegroundColor "Green" "done."

Write-Host -ForegroundColor "Green" "Installing steamcmd... " -NoNewline
Invoke-InstallSteamCmd -OutPath $SteamDir
Write-Host -ForegroundColor "Green" "done."

Write-Host -ForegroundColor "Green" "Installing NS2... " -NoNewline
Invoke-InstallNS2 -SteamPath $SteamDir -Username $Username -Password $Password -NS2Path $NS2Dir
Write-Host -ForegroundColor "Green" "done."

Write-Host -ForegroundColor "Green" "Updating system firewall... " -NoNewline
Set-NS2FirewallRule -NS2Path $NS2Dir
Write-Host -ForegroundColor "Green" "done."

Write-Host
Write-Host "You should be good to go. :]"
Write-Host ">> " + (join-path $NS2Dir "x64/server.exe") 
Write-Host