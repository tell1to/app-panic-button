@echo off
REM Script para obtener SHA-1 del debug keystore

REM Buscar Java en rutas comunes
set JAVA_HOME_PATHS=^
    "C:\Program Files\Java"^
    "C:\Program Files (x86)\Java"^
    "%JAVA_HOME%"

for %%P in (%JAVA_HOME_PATHS%) do (
    if exist "%%P\bin\keytool.exe" (
        echo Encontrado Java en: %%P
        "%%P\bin\keytool.exe" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
        exit /b 0
    )
)

REM Si no lo encuentra en rutas comunes, intentar buscar en registry
echo No se encontro Java en rutas comunes
echo Buscando en registry...

for /f "tokens=2*" %%A in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft\Java Runtime Environment" /v CurrentVersion 2^>nul ^| find "CurrentVersion"') do (
    set JRE_VERSION=%%B
)

if defined JRE_VERSION (
    for /f "tokens=2*" %%A in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft\Java Runtime Environment\%JRE_VERSION%" /v JavaHome 2^>nul ^| find "JavaHome"') do (
        set JAVA_PATH=%%B
    )
)

if defined JAVA_PATH (
    echo Encontrado Java en: %JAVA_PATH%
    "%JAVA_PATH%\bin\keytool.exe" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
) else (
    echo ERROR: No se pudo encontrar Java
    echo Asegurate de que Java esté instalado
    pause
)
