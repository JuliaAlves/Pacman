@echo off

path %PATH%;c:\masm32\bin

echo Criando diret¢rios...

md "bin" >nul 2>&1
md "obj" >nul 2>&1

echo Compilando recursos...

del "build.log" >nul 2>&1

rc /v /fo "obj\rsrc.res" "src\rsrc.rc" >>"build.log" 2>&1
if errorlevel 1 goto resourceerror

echo Convertendo .RES para .OBJ...
cvtres /machine:ix86 "obj\rsrc.res" /OUT:"obj\rsrc.obj" >>"build.log" 2>&1
if errorlevel 1 goto resourcecvterror

echo Compilando c¢digo...
ml /c /coff /Fo"obj\pacman.obj" "src\graphics.asm" "src\pacman.asm" "src\main.asm" >>"build.log" 2>&1
if errorlevel 1 goto compileerror

echo Gerando execut vel...
\masm32\bin\link /SUBSYSTEM:WINDOWS /OPT:NOREF "obj\pacman.obj" "obj\rsrc.obj" /OUT:"bin\pacman.exe" >>"build.log" 2>&1
if errorlevel 1 goto linkerror

echo Executando...
call "bin/pacman.exe"
goto :eof

:resourceerror

echo.
echo Erro na compila‡?o dos recursos. Abortando.
goto eof

:resourcecvterror

echo.
echo Erro na convers?o dos recursos. Abortando.
goto eof

:compileerror

echo.
echo Erro na compila‡?o. Abortando.
goto eof

:linkerror

echo.
echo Erro na linkagem. Abortando.
goto eof

:eof