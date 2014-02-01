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


// defines specific to core.lsl


#ifndef _CORE
#define _CORE


#define Vec2Rot(_v)                llEuler2Rot((_v) * DEG_TO_RAD)
#define boolIsAgent(_k)            (ZERO_VECTOR != llGetAgentSize(_k))

#define boolInvalidSlotNo(_no)     (((_no) < 0) || ((_no) > slotMax))


int status;
#define stADJUSTERS                1
#define stEXPLICIT                 2



integer btnline;
integer chatchannel;
integer curPrimCount = 0;
integer lastPrimCount = 0;
integer lastStrideCount;
integer line;
integer slotMax = 0;

key btnid;
key clicker;
key dataid;
key hudId;

string btncard;
string card;

list slots;


#endif  // _CORE
