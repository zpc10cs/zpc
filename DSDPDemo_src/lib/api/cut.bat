@echo off&setlocal enabledelayedexpansion
pushd %~dp0
for /f "delims=" %%i in ('dir /s /b *.jar') do (
set m=%%i
set u=!m:-V500R005C00B010-SNAPSHOT=!
move "%%i" "!u: =!" 
)

for /f "delims=" %%i in ('dir /s /b *.jar') do (
set m=%%i
set u=!m:-V500R005C00B020-SNAPSHOT=!
move "%%i" "!u: =!" 
)

for /f "delims=" %%i in ('dir /s /b *.jar') do (
set m=%%i
set u=!m:-V500R005C00B030-SNAPSHOT=!
move "%%i" "!u: =!" 
)