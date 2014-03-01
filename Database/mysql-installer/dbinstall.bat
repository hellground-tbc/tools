@echo off
setlocal
set log=%0%.log

echo -----------------------------------
echo -- HellGround Database Installer --
echo -----------------------------------
echo/
echo This is the HellGround Database installer script for use with MySQL.
echo Before starting, __MAKE SURE__ you have created and configured 3 databases
echo for the core to use: characters, realmd, world (names can be arbitrary)
echo and you run this script from the root of HellGround Database repository.
echo/

echo -- World.sql check --
if not exist world.sql (
    echo [Error] World.sql not found. Extract world.sql.gz contents and try again.
    goto eof
)

echo [Info] World database file found.
echo/

echo -- Set up MySQL connection --
:mysql
set /p dbUser=User name: 
set /p dbPass=User pass: 

echo \q | mysql -u%dbUser% -p%dbPass% 2>nul || echo [Error] Database connection failed. && goto mysql

echo [Info] Database connection successful.
echo/

echo -- Set up database names --
:dbworld
set /p dbWorld=World database: 
echo USE %dbWorld%; | mysql -u%dbUser% -p%dbPass% 2>nul || echo [Error] Database %dbWorld% does not exist. && goto dbworld

:dbrealmd
set /p dbRealmd=Realmd database: 
echo USE %dbRealmd%; | mysql -u%dbUser% -p%dbPass% 2>nul || echo [Error] Database %dbRealmd% does not exist. && goto dbrealmd

:dbchars
set /p dbChars=Characters database: 
echo USE %dbChars%; | mysql -u%dbUser% -p%dbPass% 2>nul || echo [Error] Database %dbChars% does not exist. && goto dbchars

echo [Info] All databases set successfully.
echo/

echo -- Apply SQL structure files --
echo * structures\characters_struct.sql && mysql -u%dbUser% -p%dbPass% %dbChars% <structures\characters_struct.sql 2>%log% || goto err
echo * structures\characters_data.sql && mysql -u%dbUser% -p%dbPass% %dbChars% <structures\characters_data.sql 2>%log% || goto err
echo * structures\realm_struct.sql && mysql -u%dbUser% -p%dbPass% %dbRealmd% <structures\realm_struct.sql 2>%log% || goto err
echo * structures\realm_data.sql && mysql -u%dbUser% -p%dbPass% %dbRealmd% <structures\realm_data.sql 2>%log% || goto err
echo * structures\world_struct.sql && mysql -u%dbUser% -p%dbPass% %dbWorld% <structures\world_struct.sql 2>%log% || goto err
echo * world.sql && mysql -u%dbUser% -p%dbPass% %dbWorld% <world.sql 2>%log% || goto err
echo [Info] Structures applied successfully.
echo/

echo -- Apply SQL updates --
if not exist combine_sql.bat (
    echo [Warning] SQL combiner not found. You have to apply updates manually.
    echo/
    goto realm
)

echo [Info] Combining updates...
call combine_sql.bat >nul
echo [Info] Applying updates...
echo * combined_characters.sql && mysql -u%dbUser% -p%dbPass% %dbChars% <combined_characters.sql 2>%log% || goto err
echo * combined_realm.sql && mysql -u%dbUser% -p%dbPass% %dbRealmd% <combined_realm.sql 2>%log% || goto err
echo * combined_world.sql && mysql -u%dbUser% -p%dbPass% %dbWorld% <combined_world.sql 2>%log% || goto err
del combined_*.sql
echo [Info] Update finished successfully.
echo/

:realm
echo -- Add realm --
set /p rname=Realm name: 
set /p rip=Realm IP: 
echo INSERT INTO `realms` (`name`, `ip_address`) VALUES ('%rname%', '%rip%'); | mysql -u%dbUser% -p%dbPass% %dbRealmd% 2>%log% || goto err
echo [Info] Realm added successfully.
echo/

echo [Info] Cleaning up...
del %log%

echo [Info] Database installation finished successfully.
echo [Info] You may now add administrator account using server console.
goto eof

:err
echo [Error] Database error encountered:
type %log%

:eof
