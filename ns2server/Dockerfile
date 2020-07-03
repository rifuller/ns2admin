FROM mcr.microsoft.com/windows/servercore:2004-amd64
COPY dlls/System32/avifil32.dll C:/Windows/System32/avifil32.dll
COPY dlls/System32/msacm32.dll C:/Windows/System32/msacm32.dll
COPY dlls/System32/msvfw32.dll C:/Windows/System32/msvfw32.dll
COPY dlls/SysWOW64/avifil32.dll C:/Windows/SysWOW64/avifil32.dll
COPY dlls/SysWOW64/msacm32.dll C:/Windows/SysWOW64/msacm32.dll
COPY dlls/SysWOW64/msvfw32.dll C:/Windows/SysWOW64/msvfw32.dll

ENV STEAMAPPID 4940
ENV STEAMAPPDIR="C:/steamcmd"
ENV GAMEDIR "C:/NS2Server"

SHELL ["powershell", "-Command"]
RUN iwr https://github.com/PowerShell/PowerShell/releases/download/v7.0.2/PowerShell-7.0.2-win-x64.msi -UseBasicParsing -OutFile PowerShell-7-win-x64.msi
RUN Start-Process "PowerShell-7-win-x64.msi /q" -PassThru | Wait-Process
RUN rm "PowerShell-7-win-x64.msi"

SHELL ["pwsh", "-Command"]
RUN iwr https://aka.ms/vs/16/release/vc_redist.x64.exe -UseBasicParsing -OutFile vc_redist.x64.exe \
    && Start-Process "vc_redist.x64.exe /q" -PassThru | Wait-Process \
    && rm "vc_redist.x64.exe"

RUN iwr http://us.download.nvidia.com/Windows/9.19.0218/PhysX-9.19.0218-SystemSoftware.exe -UseBasicParsing -OutFile PhysX.exe \
    && Start-Process "PhysX.exe /quiet"

RUN iwr http://media.steampowered.com/installer/steamcmd.zip -UseBasicParsing -OutFile steamcmd.zip \
    && Expand-Archive -Path steamcmd.zip -Destination $ENV:STEAMAPPDIR \ 
    && rm steamcmd.zip

WORKDIR ${STEAMAPPDIR}
CMD ["pwsh", "entry.ps1"]

COPY entry.ps1 "${STEAMAPPDIR}/entry.ps1"

EXPOSE 27015/tcp 27015/udp 27016/tcp 27016/udp 8766/udp