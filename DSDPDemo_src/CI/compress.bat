@ECHO OFF
cd %~dp0\..

set /p repo_dir=please input local repository's full path(e.g. F:\myrepo):

rd /S /Q maven_lib
rd /S /Q target
rd /S /Q %repo_dir% 
md %repo_dir%
del /A /Q DSDPDemo_src.zip
del /A /Q DSDPDemo_Maven_Repository.zip
del /A /Q common_sdk_lib.zip

cd install
del /A /Q DSDPDemo_V500R005C00_install.zip

cd ..

call mvn clean install -Dmaven.repo.local=%repo_dir% -Dmaven.test.skip=true

rd /S /Q %repo_dir%\.locks
rd /S /Q %repo_dir%\.cache
del /S /F /Q %repo_dir%\*.sha1
del /S /F /Q %repo_dir%\*.repositories
del /S /F /Q %repo_dir%\*.sha1-in-progress
del /S /F /Q %repo_dir%\*.properties
del /S /F /Q %repo_dir%\*.lastUpdated

set /p zip_dir=please input 7zip full path(The path can not contain blank.  e.g. D:\7-Zip\7z.exe):

%zip_dir% a -tzip "DSDPDemo_src.zip" "*" -x!".git"
IF  ERRORLEVEL 1 EXIT
%zip_dir% a -tzip "DSDPDemo_Maven_Repository.zip" "%repo_dir%\*" -x!".git" 
IF  ERRORLEVEL 1 EXIT 

cd CI
call package-maven.bat
IF  ERRORLEVEL 1 EXIT

cd maven_lib
%zip_dir% a -tzip "..\common_sdk_lib.zip" "lib\*" 