SET filename=MAIN

TOOLS\TASM.EXE graphics\SRC\%filename%.ASM /w2 /la /zi graphics\BUILD\
TOOLS\TLINK.EXE /v graphics\BUILD\%filename%.OBJ, graphics\BUILD\PAINTER.EXE, graphics\BUILD\%filename%.MAP
COPY graphics\BUILD\PAINTER.exe PAINTER.exe
