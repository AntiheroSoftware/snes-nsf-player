#define DEBUG_TILE_ADDR	0x2000
#define DEBUG_MAP_ADDR  0x1000

extern byte cursorX, cursorY;
extern word debugMap[0x400];

void initDebug(void);
void setCursorDebug(int x, int y);
void writeStringDebug(char out[]);
void writeFarStringDebug(char far out[]);
void displayDebug(void);
char displayDebugEvent(word counter);
