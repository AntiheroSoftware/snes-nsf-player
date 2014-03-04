ERASE=rm --force
COPY=cp

WDCROOT=/home/lint/.wine/drive_c/65xx_FreeSDK/
WDCBIN=/home/lint/.wine/drive_c/65xx_FreeSDK/bin/

CC=$(WDCBIN)WDC816CC.exe
AS=$(WDCBIN)WDC816AS.exe
LN=$(WDCBIN)WDCLN.exe

SRC_C= $(wildcard *.c)
SRC_ASM= $(wildcard *.asm)

OBJ= $(SRC_C:.c=.o)
OBJ+= $(SRC_ASM:.asm=.o)

all: clean nsf_player.smc

nsf_player.smc : $(OBJ) spc.bin
	$(LN) -HB -M21 -V -T -PFF \
		-C8000,0000 \
		-D, \
		-U0800,0000 \
		-Avectors=FFE4,7FE4 \
		-Aregistration_data=FFB0,7FB0 \
		-Aressource=18000,8000 \
		-Anes_code=88000,40000 \
		-Aspc_code=38000,18000 \
		-N \
		$(OBJ) \
		-L"../Snes Lib/lib/snes" \
		-L$(WDCROOT)/lib/cs -O nsf_player.smc
	tools/padbin.exe 0x40000 nsf_player.smc

%.o: %.c
	$(CC) -I "../Snes Lib/include" -AT -QV -wl -wp -sop -MS $< -o $(@:.o=.a)
	$(CC) -I "../Snes Lib/include" -QV -wl -wp -sop -MS $< -o $@

%.o: %.asm
	$(AS) -V -L $< -o $@

spc.bin: 
	cd SPC && ../tools/tasm.exe -t07 -b spc.asm && $(COPY) SPC.OBJ ../SPC.bin && cd ..

spc-disassembly:
	spcdas SPC.BIN SPC.BIN.a
	spcdas SPC_ORIG.BIN SPC_ORIG.BIN.a

clean:
	-$(ERASE) *.obj
	-$(ERASE) *.o
	-$(ERASE) *.lst
	-$(ERASE) *.usage
	-$(ERASE) *.map
	-$(ERASE) nsf_player.smc
	-$(ERASE) Valid.Ext
