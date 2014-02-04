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



#define MemTell \
	apf("\n", llGetScriptName(), "\n", llGetMemoryLimit(), "max\n", llGetUsedMemory(), "used\n", llGetFreeMemory(), "free\n", llGetMemoryLimit() - llGetUsedMemory() - llGetFreeMemory(), "gc")



#endif  // _CONSTANTS
