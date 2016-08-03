
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


echo 0. Create table (in Coder) if it does not exist

sqlcmd -S %server% -d %database% -U %user% -P %password% -i RaveExtractCreateTable.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -i RequeueDatapoints.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -i CoderCorrelationCreateTable.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -i CoderCMPTable.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -i RaveCoderBatch.sql
if %ERRORLEVEL% NEQ 0 goto errors


echo 2.  correlate data create functions

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i fnGetCompositeKey.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i fnGetInfoFromHash.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i fngetCodingValues.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i fnDecompress.sql
if %ERRORLEVEL% NEQ 0 goto errors


echo 3.  correlate data create stored procedures

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i spPreProcessRaveDataSet.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i spPreProcessCoderDataSet.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i spPartialCorrelateCoderTasks.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i spCoderRaveCorrelationView.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i spGenerateFullKeys.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i spFullCorrelateCoderTasks.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i spDataCorrelation.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i spPopulateRaveRequeue.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i spPrepCMP.sql 
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i spCorrelateCoderTasks.sql
if %ERRORLEVEL% NEQ 0 goto errors

sqlcmd -S %server% -d %database% -U %user% -P %password% -I -i spRunBatch.sql
if %ERRORLEVEL% NEQ 0 goto errors




echo.
echo Object creation completed successfully!

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