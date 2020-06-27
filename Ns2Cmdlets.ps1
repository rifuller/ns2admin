function NS2-InstallPrerequisites {
   param()

    Write-Host -ForegroundColor "Green" "Installing Prerequisites..."
    Invoke-WebRequest -Uri http://us.download.nvidia.com/Windows/9.19.0218/PhysX-9.19.0218-SystemSoftware.exe -UseBasicParsing -OutFile PhysX-9.19.0218-SystemSoftware.exe
    PhysX-9.19.0218-SystemSoftware.exe

    Invoke-WebRequest -Uri https://aka.ms/vs/16/release/vc_redist.x64.exe -UseBasicParsing -OutFile vc_redist.x64.exe
    vc_redist.x64.exe

    #PS C:\Windows\SysWOW64> cp W:\SysWOW64\msacm32.dll .
    #PS C:\Windows\SysWOW64> cp W:\SysWOW64\avifil32.dll .
    #PS C:\Windows\SysWOW64> cp W:\SysWOW64\msvfw32.dll .
    #PS C:\Windows\SysWOW64> cp W:\SysWOW64\msvfw32.dll .\
    #PS C:\Windows\SysWOW64> cd ..\system32
    #PS C:\Windows\system32> cp W:\system32\avifil32.dll .
    #PS C:\Windows\system32> cp W:\system32\msacm32.dll .
    #PS C:\Windows\system32> cp W:\system32\msvfw32.dll .
    Write-Host -ForegroundColor "Green" "Done."
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



