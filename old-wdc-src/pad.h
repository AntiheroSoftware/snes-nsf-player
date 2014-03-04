typedef struct padStatus{
	byte right:1;
	byte left:1;
	byte down:1;
	byte up:1;	
	byte start:1;	// Enter
	byte select:1;	// Space
	byte Y:1;	// X
	byte B:1;	// Cs
	byte Dummy:4;
	byte R:1;	// Z
	byte L:1;	// A
	byte X:1; 	// S
	byte A:1;	// D
} padStatus;

void enablePad(void);
void clearPad(padStatus pad);
padStatus readPad(byte padNumber);
