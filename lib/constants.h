// The nPose scripts are licensed under the GPLv2
// (http://www.gnu.org/licenses/gpl-2.0.txt), with the following
// addendum:
//
// The nPose scripts are free to be copied, modified, and
// redistributed, subject to the following conditions:
//
//    - If you distribute the nPose scripts, you must leave them full
//      perms.
//
//    - If you modify the nPose scripts and distribute the
//      modifications, you must also make your modifications full
//      perms.
//
// "Full perms" means having the modify, copy, and transfer
// permissions enabled in Second Life and/or other virtual world
// platforms derived from Second Life (such as OpenSim).  If the
// platform should allow more fine-grained permissions, then "full
// perms" will mean the most permissive possible set of permissions
// allowed by the platform.


// This file contains defines for constants that replace variables
// which were abused as constants.  Defines for some hard-coded
// constants have been added.
//

#ifndef _CONSTANTS
#define _CONSTANTS


#define ADJUST                     201
#define ADJUSTOFFSET               208
#define CORERELAY                  300
#define DOACTIONS                  207
#define DOPOSE                     200
#define DUMP                       204
#define SEND_CHATCHANNEL        999999
#define SETOFFSET                  209
#define STOPADJUST                 205
#define SWAP                       202
#define SWAPTO                     210
#define SYNC                       206
#define adminHudName                              "npose admin hud"
#define avatarOffsetsLength         20
#define cardprefix                                "SET:"
#define defaultprefix                             "DEFAULT:"
#define iADJUST_UPDATE               3
#define iADJUST_UPDATE_ADJUSTERS(_num, _str)      (2 == (_num) && "RezAdjuster" == (_str))
#define iBUTTONUPDATE                             (seatupdate + 1)
#define iRCV_CHATCHANNEL             1
#define iTOGGLE_FACIALS           -241
#define iUNSIT                    -222
#define layerPose                 -218
#define memusage                 34334
#define sSEAT                                     "seat"
#define seatupdate               35353
#define slotupdate               34333
#define stride                       8


// define USE_NiceMemstat to get nice memory statistics
//
// This eats about 2--3kB when outlined and 12kB or so when not
// outlined because something like snprintf() is missing.  The scripts
// look as if something like -funroll-loops was enabled when
// virtualsprintf_float() is not outlined ;)
//
#define USE_NiceMemstat

// define OUTLINE_virtualsprintf_float to make virtualsprintf_float()
// a function
//
// uses less memory when USE_NiceMemstat is defined, otherwise more
//
#define OUTLINE_virtualsprintf_float
//
// so just define it when USE_NiceMemstat is defined
//
#ifdef USE_NiceMemstat
#ifndef OUTLINE_virtualsprintf_float
#define OUTLINE_virtualsprintf_float
#endif
#endif
//
// and don´t define USE_NiceMemstat when OUTLINE_virtualsprintf_float
// is not defined
//
#ifndef USE_NiceMemstat
#undef OUTLINE_virtualsprintf_float
#endif
// so whatever ...
//
// Only touch USE_NiceMemstat to toggle.
//
// /


#ifdef USE_NiceMemstat
// printf() is soooo missing from LSL :((((
//
#define virtualsprintf_float(_n, $_fmt, _null, _ret)			\
	{								\
		_ret = "";						\
		int $_ = ($_fmt) + 1;					\
		LoopDown($_, _ret += _null);				\
		_ret += (string)(_n);					\
		$_ = ($_fmt) + 1;					\
		while(Strlen(Begstr(_ret, Stridx(_ret, "."))) > $_)	\
			{						\
				_ret = Endstr(_ret, 1);			\
			}						\
	}
#endif


#ifdef OUTLINE_virtualsprintf_float

#ifdef USE_NiceMemstat

// printf() is soooo missing from LSL :((((
//
string sprintf_float(float _n, int $_fmt)
{
	string _ret;
	virtualsprintf_float(_n, $_fmt, " ", _ret);
	return _ret;
}


#define MemTell							\
	{							\
		float limit = (float)llGetMemoryLimit();	\
		float free = (float)llGetFreeMemory();		\
		float used = (float)llGetUsedMemory();		\
		float gc = limit - free - used;			\
								\
		float pfree = free * 100.0 / limit;		\
		float pused = used * 100.0 / limit;		\
		float pgc = gc * 100.0 / limit;			\
								\
		apf("\n", llGetScriptName(), "\n",		\
		    sprintf_float(limit, 5),			\
		    "max\t\t100 % max\n",			\
		    sprintf_float(used, 5),			\
		    "used\t", sprintf_float(pused, 5),		\
		    "% used\n", sprintf_float(free, 5),		\
		    "free\t", sprintf_float(pfree, 5),		\
		    "% free\n", sprintf_float(gc, 5),		\
		    "gc\t", sprintf_float(pgc, 7), "% gc");	\
	}

#else  // OUTLINE_virtualsprintf_float

#define MemTell                    llSay(PUBLIC_CHANNEL, concat(llGetScriptName(), concat(" ", concat((string)llGetFreeMemory(), " bytes free"))))

#endif  // USE_NiceMemstat

#else

#ifdef USE_NiceMemstat

#define MemTell								\
	{								\
		float limit = (float)llGetMemoryLimit();		\
		float free = (float)llGetFreeMemory();			\
		float used = (float)llGetUsedMemory();			\
		float gc = limit - free - used;				\
									\
		float pfree = free * 100.0 / limit;			\
		float pused = used * 100.0 / limit;			\
		float pgc = gc * 100.0 / limit;				\
									\
		string slimit;						\
		string sfree;						\
		string sused;						\
		string sgc;						\
		string spfree;						\
		string spused;						\
		string spgc;						\
									\
		virtualsprintf_float(limit, 5, " ", slimit);		\
		virtualsprintf_float(free, 5, " ", sfree);		\
		virtualsprintf_float(used, 5, " ", sused);		\
		virtualsprintf_float(gc, 5, " ", sgc);			\
		virtualsprintf_float(pfree, 5, " ", spfree);		\
		virtualsprintf_float(pused, 5, " ", spused);		\
		virtualsprintf_float(pgc, 7, " ", spgc);		\
									\
		apf("\n", llGetScriptName(), "\n", slimit, "max\t\t100 % max\n", sused, "used\t", spused, "% used\n", sfree, "free\t", spfree, "% free\n", sgc, "gc\t", spgc, "% gc"); \
	}

#else

#define MemTell                    llSay(PUBLIC_CHANNEL, concat(llGetScriptName(), concat(" ", concat((string)llGetFreeMemory(), " bytes free"))))

#endif  // USE_NiceMemstat

#endif  // OUTLINE_virtualsprintf_float



#endif  // _CONSTANTS
