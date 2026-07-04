@echo off
rem Builds the vendored Box2D C library into a static archive that dub links.
rem Invoked by dub via preBuildCommands. Safe to run repeatedly (incremental).
setlocal
set DIR=%~dp0
set SRC=%DIR%box2d
set BUILD=%SRC%\build

where cmake >nul 2>nul
if errorlevel 1 (
    echo box2d.d: cmake is required to build the vendored Box2D library. 1>&2
    echo          Install cmake, or use the "system" configuration to link a system Box2D. 1>&2
    exit /b 1
)

cmake -S "%SRC%" -B "%BUILD%" -DCMAKE_BUILD_TYPE=Release >nul || exit /b 1
cmake --build "%BUILD%" --config Release >nul || exit /b 1

rem Locate the built import/static library across generator layouts.
if exist "%BUILD%\Release\box2d.lib" (
    copy /y "%BUILD%\Release\box2d.lib" "%DIR%box2d.lib" >nul
) else if exist "%BUILD%\box2d.lib" (
    copy /y "%BUILD%\box2d.lib" "%DIR%box2d.lib" >nul
) else (
    echo box2d.d: failed to locate built box2d.lib under %BUILD% 1>&2
    exit /b 1
)
