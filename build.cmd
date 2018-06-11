@echo off
echo Criando diretorios...

md "bin" >nul 2>&1
md "obj" >nul 2>&1

echo Compilando recursos...

del "build.log" >nul 2>&1

c:\masm32\bin\rc /v /fo "obj\rsrc.res" "src\rsrc.rc" >>"build.log" 2>&1
if errorlevel 1 goto :resourceerror

echo Convertendo .RES para .OBJ...
c:\masm32\bin\cvtres /machine:ix86 "obj\rsrc.res" /OUT:"obj\rsrc.obj" >>"build.log" 2>&1
if errorlevel 1 goto :resourcecvterror

echo Compilando codigo...
c:\masm32\bin\ml /c /coff /Fo"obj\graphics.obj" "src\graphics.asm" >>"build.log" 2>&1
if errorlevel 1 goto :compileerror

c:\masm32\bin\ml /c /coff /Fo"obj\pacman.obj" "src\pacman.asm" >>"build.log" 2>&1
if errorlevel 1 goto :compileerror

c:\masm32\bin\ml /c /coff /Fo"obj\sound.obj" "src\sound.asm" >>"build.log" 2>&1
if errorlevel 1 goto :compileerror

c:\masm32\bin\ml /c /coff /Fo"obj\main.obj" "src\main.asm" >>"build.log" 2>&1
if errorlevel 1 goto :compileerror

echo Gerando executavel...
c:\masm32\bin\link /SUBSYSTEM:WINDOWS /OPT:NOREF "obj\main.obj" "obj\sound.obj" "obj\graphics.obj" "obj\pacman.obj" "obj\rsrc.obj" /OUT:"bin\pacman.exe" >>"build.log" 2>&1
if errorlevel 1 goto :linkerror

echo Copiando DLLs...
copy astar.dll bin\astar.dll

echo Executando...
call "bin/pacman.exe"
goto :eof

:resourceerror

echo.
echo Erro na compilacao dos recursos. Abortando.
call "build.log"
goto :eof

:resourcecvterror

echo.
echo Erro na conversao dos recursos. Abortando.
call "build.log"
goto :eof

:compileerror

echo.
echo Erro na compilacao. Abortando.
call "build.log"
goto :eof

:linkerror

echo.
echo Erro na linkagem. Abortando.
call "build.log"
goto :eof

:eof