#include "data.h";
#include "pad.h";

void enablePad(void) {
	// Enable pad reading and NMI
	*(byte*)0x4200 = 0x81;
}

void clearPad(padStatus pad) {
	word test;

	test = 0;
	pad = (word) test;
}

padStatus readPad(byte padNumber) {
	word test;
	padStatus *status;
	
	padNumber = padNumber << 1;

	// if pad data still reading we wait
	while((*(byte*)0x4212 & 0x01)) { }

	test = (word) *(byte*)0x4218+padNumber << 8;
	test |= (word) *(byte*)0x4219+padNumber;

	status = (padStatus *) &test;
	
	return *status;
}


