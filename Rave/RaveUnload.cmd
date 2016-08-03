@echo off
REM: Authentication type: Windows NT
REM: Usage: CommandFilename [User] [Password] [Database] [Server] 

set user=%1
set password=%2
set database=%3
set server=%4
set ravetoken=%5

shift

if "%user%" == "" goto usage
if "%password%" == "" goto usage
if "%database%" == "" goto usage
if "%server%" == "" goto usage

sqlcmd -S %server% -d %database% -U %user% -P %password% -i RaveExtractCreateTable.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -i fnWebServicesGetNestedFolderPath.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i spRaveCoderExtract.sql 
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password%  -b -n -Q "exec spRaveCoderExtract $(ravetoken)"
if %ERRORLEVEL% NEQ 0 goto errors

bcp [%database%].dbo.RaveCoderExtract format nul -c -f RaveCoderExtract.fmt -U %user% -P %password% -S %server%
if %ERRORLEVEL% NEQ 0 goto errors

bcp [%database%].dbo.RaveCoderExtract out RaveCoderExtract_%ravetoken%.txt -f RaveCoderExtract.fmt -U %user% -P %password% -S %server%
if %ERRORLEVEL% NEQ 0 goto errors

echo.
echo Script execution completed successfully!
goto finish

REM: How to use screen
:usage
echo.
echo Usage: MyScript User Password Database Server
echo User: The database user
echo Password: The database user password
echo Database: the name of the target database
echo Server: the name of the target SQL Server
echo.
echo Example: MyScript.cmd user password dbInstance DD58ZMLF1\AVINSTANCE2 
echo.
goto done

REM: error handler
:errors
echo.
echo WARNING! Error(s) were detected!
echo --------------------------------
echo Please evaluate the situation and, if needed,
echo restart this command file. You may need to
echo supply command parameters when executing
echo this command file.

echo.
goto done

REM: finished execution
:finish
:done
REM: pause
@echo on