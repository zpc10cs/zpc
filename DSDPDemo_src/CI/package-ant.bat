@ECHO ON
REM set path=%path%;%cd%\CI

call ant -f build_dsdpdemo_jar.xml > deploy.log
IF ERRORLEVEL 1 EXIT
echo "DSDPDEMO deploy complete">> deploy.log

call ant -f build_dsdpdemo_ideploy_pkg.xml > package.log
IF ERRORLEVEL 1 EXIT
echo "DSDPDEMO package complete" >> package.log
