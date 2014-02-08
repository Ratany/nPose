

#include <lslstddef.h>
#include <constants.h>

#define iITEMS                     100

#define iSTRIDE_test               2

#define _REPLACE

list test;


 default
 {
	 event touch_start(int t)
	 {
		 DEBUGmsg("---------- touched ----------");
		 test = [];
		 MemTell;
		 DEBUGmsg("filling list");
		 int $_ = iITEMS;
		 LoopDown($_, test += ([llGenerateKey(), llGenerateKey()]));
		 MemTell;

		 DEBUGmsg("replacing items");
		 $_ = iITEMS / iSTRIDE_test;
#ifdef _REPLACE
		 LoopDown($_, test = llListReplaceList(test, [llGenerateKey(), llGenerateKey()], $_ * iSTRIDE_test, $_ * iSTRIDE_test + 1));
#else
		 LoopDown($_, test = llDeleteSubList(test, $_ * iSTRIDE_test, $_ * iSTRIDE_test + 1); test += ([llGenerateKey(), llGenerateKey()]));
#endif
		 MemTell;
		 llSetTimerEvent(60.0);
	 }
	 event timer()
	 {
		 DEBUGmsg("timer");
		 MemTell;
		 llSetTimerEvent(0.0);
	 }
 }
