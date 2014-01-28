

// don´t require cardid to be a global variable
// resets core whenever inventory changes
//
#define _NOCARDID

// when no slot is free, returns < 0 when inlined, -1 when not inlined
//
// it suffices to define this
//
#define _INLINE_FindEmptySlot

// define _INLINE_ReadCard to 0 to disable the inlining
//
#ifdef _NOCARDID
#define _INLINE_ReadCard           1
#else
// it might be good to inline it in both cases
// both cases require changes
//
#define _INLINE_ReadCard           0
#endif
