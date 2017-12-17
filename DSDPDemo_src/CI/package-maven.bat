@ECHO ON
REM set path=%path%;C:\Program Files\apache-maven-3.1.0\bin;%cd%\CI

cd ..
call mvn clean compile deploy -Dmaven.test.skip=true > CI\deploy.log
IF  ERRORLEVEL 1 EXIT
echo "DSDPDEMO deploy complete" >> CI\deploy.log

rd /S /Q maven_lib
md maven_lib
md maven_lib\lib
md maven_lib\lib\3rd
md maven_lib\lib\api
md maven_lib\lib\commons
md maven_lib\lib\soabean

cd dsdp.demo.dependency

rd /S /Q lib

call mvn dependency:copy-dependencies -DoutputDirectory=lib -DincludeScope=runtime >copy_dependencies.log

cd lib

del /Q dsdp.demo.*.jar
rem del /Q spring-*.jar 
del /Q scp-*.jar
del /Q edu.umd.cs.findbugs*.jar

move /Y commons.*.jar ..\..\maven_lib\lib\commons\

move /Y com.huawei.csc.*.jar ..\..\maven_lib\lib\soabean\
move /Y com.huawei.soa.*.jar ..\..\maven_lib\lib\soabean\
move /Y com.huawei.openas.*.jar ..\..\maven_lib\lib\soabean\
move /Y com.huawei.itpaas.*.jar ..\..\maven_lib\lib\soabean\
move /Y com.huawei.gcu.*.jar ..\..\maven_lib\lib\soabean\
move /Y com.huawei.bme.*.jar ..\..\maven_lib\lib\soabean\

move /Y *.jar ..\..\maven_lib\lib\3rd\

cd ..\..\

copy CI\cut.bat maven_lib\lib\api\
copy CI\cut.bat maven_lib\lib\commons\

cd maven_lib\lib\api\
call cut.bat

cd ..\commons\
call cut.bat

cd ..\..\..\

call mvn package assembly:assembly -Pdsdpdemo-package -Dmaven.test.skip=true -DartifactsDir=target > CI\package.log

cd target\assembly\
ren dsdp.demo-*-DSDPDEMO_V500R005C00.tar.gz DSDPDEMO_V500R005C00.tar.gz 
ren dsdp.demo-*-DSDPDEMODB_V500R005C00.tar.gz DSDPDEMODB_V500R005C00.tar.gz 

cd ..\..\
ant -f CI/build_ideploy_pkg.xml >> CI\package.log
echo "DSDPDEMO deploy complete" >> CI\deploy.log
