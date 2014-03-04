#include "data.h"
#include "pad.h"
#include "PPU.h"
#include "PPURegisters.h"
#include "ressource.h"
#include "string.h"
#include "debug.h"
#include "event.h"

//#include <stdlib.h>

byte cursorX, cursorY;
word debugMap[0x400];

void initDebug(void) {
	word i;

	for(i=0; i<0x400; i++) {
		debugMap[i] = 0x00;
	}
}

void setCursorDebug(int x, int y) {
	cursorX = (byte) x;
	cursorY = (byte) y;
}

void writeStringDebug(char out[]) {
	word i;
	char buffer;

	for(i=0; out[i] != '\0'; i++) {
		buffer = out[i];
		if((cursorX > 0x1f) || (buffer == '\n')) {
			cursorY++;
			cursorX = 0;
			if(buffer == '\n') continue;
		}
		if(buffer>='a' && buffer<='z') {
			buffer -= 0x20;
		}
		debugMap[cursorX+(cursorY*0x20)] = buffer - 0x20;
		cursorX++;
	}
}

void writeFarStringDebug(char far out[]) {
	word i;
	char buffer;

	for(i=0; out[i] != '\0'; i++) {
		buffer = out[i];
		if((cursorX > 0x1f) || (buffer == '\n')) {
			cursorY++;
			cursorX = 0;
			if(buffer == '\n') continue;
		}
		if(buffer>='a' && buffer<='z') {
			buffer -= 0x20;
		}
		debugMap[cursorX+(cursorY*0x20)] = buffer - 0x20;
		cursorX++;
	}
}

void displayDebug(void) {
	VRAMLoad2(debugMap, DEBUG_MAP_ADDR, 0x0800);
	setINIDSPDirectValue(0x0f);
}

char displayDebugEvent(word counter) {
	displayDebug();
	return EVENT_CONTINUE;
}
