# ns2admin

## First time installation

Set your administrator password. Starting from the command prompt.

```
start powershell
wget https://github.com/PowerShell/PowerShell/releases/download/v7.0.2/PowerShell-7.0.2-win-x64.msi -UseBasicParsing -OutFile PowerShell-7.0.2-win-x64.msi
PowerShell-7.0.2-win-x64.msi
```

Restart

```
start pwsh
iex (iwr -Uri https://raw.githubusercontent.com/rifuller/ns2admin/master/InstallNS2Server.ps1 -UseBasicParsing)
```

Enter your steam username and password.
Enter click through pre-reqs that pop up.
Enter steam guard code when prompted.

Run server 

`C:/NS2Server/x64/server.exe`

## Updating
You can update NS2 using the script that was created for you.

`C:/NS2server/updatens2.cmd`

## TODO

* ~~P0: Add script to install pre-reqs~~
    * ~~Download files to temp dir first, verify, then copy to the final output dir~~
* ~~P0: Script to install steamcmd~~
* P0: Run server.exe as a non-privileged account
* P1: Add default configs
* P2: Web APIs