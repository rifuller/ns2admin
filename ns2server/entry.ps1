Write-Host -ForegroundColor Green "Entering the zone."

& ($ENV:STEAMAPPDIR + "/steamcmd.exe") +login 'username' 'password' +force_install_dir $ENV:GAMEDIR +app_update $ENV:STEAMAPPID validate +quit
& ($ENV:GAMEDIR + "/x64/server.exe") -verbose 3