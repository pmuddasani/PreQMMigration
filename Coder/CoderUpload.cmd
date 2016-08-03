
@echo off

For /f "tokens=1-3 delims=/: " %%a in ('time /t') do (set StartTime=%%a:%%b %%c)
REM: Authentication type: Windows NT
REM: Usage: CommandFilename [User] [Password] [Database] [Server]

set user=%1
set password=%2
set database=%3
set server=%4

shift

if "%user%" == "" goto usage
if "%password%" == "" goto usage
if "%server%" == "" goto usage
if "%ravetoken%" == "" goto usage

if '%server%' == '/?' goto usage
if '%server%' == '-?' goto usage
if '%server%' == '?' goto usage
if '%server%' == '/help' goto usage

echo Check. Log RaveToken processing



echo 1. Import translated data from Rave

bcp [%database%].dbo.RaveCoderExtract in Data\RaveCoderExtract_%.txt -f RaveCoderExtract.fmt -U %user% -P %password% -S %server%
if %ERRORLEVEL% NEQ 0 goto errors


echo.
echo Script execution completed successfully!

For /f "tokens=1-3 delims=/: " %%a in ('time /t') do (set EndTime=%%a:%%b %%c)
echo.
echo Finished executing Import script successfully. Start-time: %StartTime% End-Time: %EndTime%.

goto finish

REM: How to use screen
:usage
echo.
echo Usage: CommandFilename [User] [Password] [Database] [Server]
echo User: The database user
echo Password: The database user password
echo Database: the name of the target database
echo Server: The target SQL server name
echo.
echo Example: CoderUpload.cmd developer developer coder_v1_14Apr2016 ec2-54-147-0-31.compute-1.amazonaws.com 407
echo.
goto done

REM: error handler
:errors
echo.
echo WARNING! Error(s) were detected!
echo --------------------------------
echo.

echo .
echo Execution of import script failed.

echo.
goto done

REM: finished execution
:finish
:done
@echo on 