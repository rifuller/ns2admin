FROM mcr.microsoft.com/windows/servercore:2004-amd64
COPY dlls/System32/avifil32.dll C:/Windows/System32/avifil32.dll
COPY dlls/System32/msacm32.dll C:/Windows/System32/msacm32.dll
COPY dlls/System32/msvfw32.dll C:/Windows/System32/msvfw32.dll
COPY dlls/SysWOW64/avifil32.dll C:/Windows/SysWOW64/avifil32.dll
COPY dlls/SysWOW64/msacm32.dll C:/Windows/SysWOW64/msacm32.dll
COPY dlls/SysWOW64/msvfw32.dll C:/Windows/SysWOW64/msvfw32.dll

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN iwr https://github.com/PowerShell/PowerShell/releases/download/v7.0.2/PowerShell-7.0.2-win-x64.msi -UseBasicParsing -OutFile PowerShell-7.0.2-win-x64.msi
RUN Start-Process "PowerShell-7.0.2-win-x64.msi /q" -PassThru | Wait-Process

RUN iwr https://aka.ms/vs/16/release/vc_redist.x64.exe -UseBasicParsing -OutFile vc_redist.x64.exe
RUN Start-Process "vc_redist.x64.exe /q" -PassThru | Wait-Process

RUN iwr http://us.download.nvidia.com/Windows/9.19.0218/PhysX-9.19.0218-SystemSoftware.exe -UseBasicParsing -OutFile PhysX-9.19.0218-SystemSoftware.exe
RUN Start-Process "PhysX-9.19.0218-SystemSoftware.exe /quiet"

RUN iwr http://media.steampowered.com/installer/steamcmd.zip -UseBasicParsing -OutFile steamcmd.zip
RUN Expand-Archive -Path steamcmd.zip -Destination "C:/steamcmd"