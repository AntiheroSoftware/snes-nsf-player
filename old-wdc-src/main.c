//#include <stdlib.h>
#include "data.h"
#include "pad.h"
#include "event.h"
#include "ressource.h"
#include "PPU.h"
#include "PPURegisters.h"
#include "debug.h"
#include "nsf_player.h"
#include "string.h"

char oncePerVBlank;
padStatus pad1;

// Events prototype
char NMIReadPad(word counter);
char oncePerVBlankReset(word counter);
char spcNsfPlayEvent(word counter);

void initInternalRegisters(void) {
	initEvents();
	initDebug();
	initRegisters();
	enablePad();
	clearPad(pad1);
	//spc_sound_init();
}

void preInit(void) {
	// For testing purpose ...
	// Insert code here to be executed before register init
}

void main(void) {

	word counter, i;
	byte songNumber;
	byte far *valuePtr;
	char buffer[32];
	char far *songName;
	char far *composerName;

	initInternalRegisters();

	// Init the song that we play by default
	songNumber = 1;
	//spc_nsf_init(songNumber);

	// Enable forced VBlank during DMA transfer
	setINIDSPDirectValue(0x80);

	// Screen map data @ VRAM location $1000
	setBG1SC(DEBUG_MAP_ADDR, (byte) 0x00);

	// Plane 0 Tile graphics @ $2000
	setBG12NBA(DEBUG_TILE_ADDR, PPU_NO_VALUE);

	// Debug tile and palette transfer to VRAM
	VRAMLoad2(debugFont_pic, DEBUG_TILE_ADDR, 0x0800);
	CGRAMLoad2(debugFont_pal, (byte) 0x00, 0x20);

	// Sprite screen data transfer to VRAM
	setINIDSPDirectValue(0x80);		// make VBlank happens
	setINIDSPDirectValue(0x00);		// free VBlank

	// TODO switch to mode 0 for trying
	setBGMODE(0, 0, 1);
	*(byte*) 0x212c = 0x01; // Plane 0 (bit one) enable register and OBJ disable
	*(byte*) 0x212d = 0x00;	// All subPlane disable
	//setINIDSP(0, 0xf);

	// set Plane 0 scroll to 0
	*(byte*) 0x210d = (byte) 0;
	*(byte*) 0x210d = (byte) 0;

	counter = 0;
	oncePerVBlank = 0;

	addEvent(&oncePerVBlankReset, 1);
	addEventWithPriority(&NMIReadPad, 1, (char) 0x00);

	setCursorDebug(0,0);
	writeStringDebug("NSF REPLAYER USING WDC v0.0.1\n\0");

	addEvent(&displayDebugEvent, 1);

	// Enable screen and disable forced VBlank
	setINIDSPDirectValue(0x0F);

	// Press start to spc_sound_init()
	setCursorDebug(0,3);
	//writeStringDebug("Press start => spc_sound_init()\n\0");
	writeStringDebug("spc_sound_init()\n\0");
	//while(pad1.start != 1) {
		// Wait
	//}
	spc_sound_init();

	// Press start to spc_nsf_init(songNumber);
	setCursorDebug(0,5);
	//writeStringDebug("Press start => spc_nsf_init()\n\0");
	writeStringDebug("spc_nsf_init()\n\0");
	//while(pad1.start != 1) {
		// Wait
	//}
	spc_nsf_init(songNumber);

	songName = (char far *) 0x7FDA0E;
	composerName = (char far *) 0x7FDA4E;

	setCursorDebug(0,25);
	writeStringDebug("Song Name : \0");
	writeFarStringDebug(songName);
	setCursorDebug(0,26);
	writeStringDebug("Composer Name : \0");
	writeFarStringDebug(composerName);

	// Press start to infinite loop
	setCursorDebug(0,7);
	//writeStringDebug("Press start => spc_nsf_play()\n\0");
	writeStringDebug("spc_nsf_play()\n\0");
	//while(pad1.start != 1) {
		// Wait
	//}
	addEvent(&spcNsfPlayEvent, 1);

	// Loop forever
	while(1) {
		if(oncePerVBlank) {
			counter++;

			if(pad1.right == 1 && songNumber < 10) {
				songNumber++;
				spc_nsf_init(songNumber);
				setCursorDebug(13,12);
				writeStringDebug("   \0");
			}

			if(pad1.left == 1 && songNumber > 0) {
				songNumber--;
				spc_nsf_init(songNumber);
				setCursorDebug(13,12);
				writeStringDebug("   \0");
			}

			if(pad1.select == 1) {
				spc_nsf_init(songNumber);
			}

			setCursorDebug(0,10);
			writeStringDebug("Counter : \0");
			itoa2(counter, buffer, 10);
			writeStringDebug(buffer);

			setCursorDebug(0,12);
			writeStringDebug("SongNumber :\n\0");
			setCursorDebug(13,12);
			itoa2(songNumber, buffer, 10);
			writeStringDebug(buffer);

			setCursorDebug(0,14);
			writeStringDebug("NSF REPLAYER REGISTERS 0x7F4100\n\0");

			setCursorDebug(0,16);
			valuePtr = (byte*) 0x7F4100;
			for(i=0; i< 0x10; i++) {
				itoa2((word) *valuePtr, buffer, 16);
				writeStringDebug(buffer);
				valuePtr++;
			}

			setCursorDebug(0,18);
			writeStringDebug("Press RESET to reset song.\n\0");

			// reset oncePerVBlank
			oncePerVBlank = 0;
		}
	}
}

void IRQHandler(void) {
}

void NMIHandler(void) {
	processEvents();
}

char NMIReadPad(word counter) {
	static byte buttonB;
	static byte buttonX;

	if(counter == 0) {
		buttonB = 0;
		buttonX = 0;
	}

	pad1 = readPad((byte) 0);

	// the buttons need to be unpressed before trigger
	if(buttonB && pad1.B) pad1.B = 0;
	else {
		if(pad1.B) buttonB = 1;
		else buttonB = 0;
	}

	if(buttonX && pad1.X) pad1.X = 0;
	else {
		if(pad1.X) buttonX = 1;
		else buttonX = 0;
	}

	return EVENT_CONTINUE;
}

char oncePerVBlankReset(word counter) {
	oncePerVBlank = 1;
	return EVENT_CONTINUE;
}

char spcNsfPlayEvent(word counter) {
	counter++;
	spc_nsf_play();
	return EVENT_CONTINUE;
}
