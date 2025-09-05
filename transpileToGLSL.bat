@echo off
@set "OUT_DIR=docs"

rem this generates %OUT_DIR%/docs and %OUT_DIR%/include from docs_src

rem skip downto MAIN to have functions on top 
GOTO:MAIN

:transpile
    SETLOCAL ENABLEDELAYEDEXPANSION
        set FILE_NAME=%~1
        set SUB_CATEGORY=%~2
        echo #define SUB_CATEGORY %SUB_CATEGORY% > input
        echo #define COPYRIGHT 0 >> input
        echo #include "docs_src/common.hlsl" >> input
        type docs_src\%FILE_NAME%.hlsl >> input
        %CLPATH%\cl.exe /EP /C input > %OUT_DIR%\docs\%FILE_NAME%_%SUB_CATEGORY%.hlsl
        echo #define SUB_CATEGORY %SUB_CATEGORY% > input
        echo #include "include/s2h_glsl.hlsl" >> input
        echo #include "docs_src/common.hlsl" >> input
        type docs_src\%FILE_NAME%.hlsl >> input
        %CLPATH%\cl.exe /EP /C input > %OUT_DIR%\docs\%FILE_NAME%_%SUB_CATEGORY%.glsl
    ENDLOCAL
EXIT /B 0


GATHER 

:MAIN

@set "CURRENT=%cd%"

@rem xcopy include\s2h.hlsl docs\include\ /y

@rem todo: improve
@set CLPATH="C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Tools\MSVC\14.29.30133\bin\HostX64\x64"

@rem /P is to run the preprocessor
@rem /E is to run the preprocessor to stdout
@rem /EP is to run the preprocessor to stdout, no adding #line
@rem /C is to keep comments
@rem > to redirect to a file
@rem >> to redirect to a file
@rem xcopy dest* 
@rem echo f | xcopy /y src dest 
@rem >2 NUL to supress error messages e.g. folder already exists

@mkdir %OUT_DIR% 2> NUL
@mkdir docs\include 2> NUL
@mkdir docs\docs 2> NUL

@rem todo: refactor to have less repetition
@type include\s2h_glsl.hlsl > input
@type include\s2h.hlsl >> input
@%CLPATH%\cl.exe /EP /C input > %OUT_DIR%\include\s2h.glsl
@%CLPATH%\cl.exe /EP /C include\s2h.hlsl > %OUT_DIR%\include\s2h.hlsl

@type include\s2h_glsl.hlsl > input
@type include\s2h_scatter.hlsl >> input
@%CLPATH%\cl.exe /EP /C input > %OUT_DIR%\include\s2h_scatter.glsl
@%CLPATH%\cl.exe /EP /C include\s2h_scatter.hlsl > %OUT_DIR%\include\s2h_scatter.hlsl

@type include\s2h_glsl.hlsl > input
@type include\s2h_3d.hlsl >> input
@%CLPATH%\cl.exe /EP /C input > %OUT_DIR%\include\s2h_3d.glsl
@%CLPATH%\cl.exe /EP /C include\s2h_3d.hlsl > %OUT_DIR%\include\s2h_3d.hlsl

rem 0..7 = let subGather = "printTxt|printDatatype|shapes|radio|button|checkbox|slider|sliderRGB";
call:transpile gather_docs 0
call:transpile gather_docs 1
call:transpile gather_docs 2
call:transpile gather_docs 3
call:transpile gather_docs 4
call:transpile gather_docs 5
call:transpile gather_docs 6

call:transpile scatter_docs 0
call:transpile scatter_docs 1
call:transpile scatter_docs 2
call:transpile scatter_docs 3
call:transpile scatter_docs 4
call:transpile scatter_docs 5
call:transpile scatter_docs 6
call:transpile scatter_docs 7

call:transpile 2d_docs 0
call:transpile 2d_docs 1
call:transpile 2d_docs 2
call:transpile 2d_docs 3
call:transpile 2d_docs 4
call:transpile 2d_docs 5
call:transpile 2d_docs 6
call:transpile 2d_docs 7
call:transpile 2d_docs 8
call:transpile 2d_docs 9
call:transpile 2d_docs 10

call:transpile 3d_docs 0
call:transpile 3d_docs 1
call:transpile 3d_docs 2
call:transpile 3d_docs 3
call:transpile 3d_docs 4
call:transpile 3d_docs 5

call:transpile ui_docs 0
call:transpile ui_docs 1
call:transpile ui_docs 2
call:transpile ui_docs 3
call:transpile ui_docs 4
call:transpile ui_docs 5

call:transpile intro 0

@rem cleanup =============================================
cd %CURRENT%
@del input





