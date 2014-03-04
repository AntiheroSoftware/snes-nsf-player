COPY=cp

all: spc.bin

spc.bin:
	../../tools/tasm.exe -t07 -b spc.asm && $(COPY) SPC.OBJ ../SPC.bin && cd ..