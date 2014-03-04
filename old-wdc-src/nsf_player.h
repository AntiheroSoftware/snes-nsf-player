void initSoundCPU(void);

void spc_sound_init(void);

// 2 parameters
// CHANGE THIS THE PARAMETERS ARE HARD CODED INTO THE CODE
//void spc_nsf_init(byte songNumber, byte system);
void spc_nsf_init(byte songNumber);
//void spc_nsf_init(void);

void spc_nsf_play(void);
void spc_sound_stop(void);
