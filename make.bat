SET filename=MAIN

TOOLS\TASM.EXE lab%1\SRC\%filename%.ASM /w2 /la /zi lab%1\BUILD\
TOOLS\TLINK.EXE /v lab%1\BUILD\%filename%.OBJ, lab%1\BUILD\%1.EXE, lab%1\BUILD\%filename%.MAP
COPY lab%1\BUILD\%1.exe %1.exe
