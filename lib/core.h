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


int status = 0;
#define stADJUSTERS                1
#define stEXPLICIT                 2
#define stREAD_BTN                 4
#define stREAD_SET                 8
#define stREAD_BTN_ONGOING        16
#define stREAD_SET_ONGOING        32


integer btnline;
integer chatchannel;
integer curPrimCount = 0;
integer lastPrimCount = 0;
integer lastStrideCount;
integer line;
integer slotMax = 0;

key btnid;
key clicker = NULL_KEY;
key dataid;
key hudId;

// used to prevent receiving slot updates sent by self
//
key kMYKEY;


string btncard;
string card;

list slots;


// list of [name, pos] to move rezzed objects into position
//
#define iSTRIDE_lRezzing           2

#define iIDX_lRezzing_Name         0
#define iIDX_lRezzing_Pos          1

#define sRezzingToName(_idx)       llList2String(lRezzing, iSTRIDE_lRezzing * _idx + iIDX_lRezzing_Name)
#define vRezzingToPos(_idx)        llList2Vector(lRezzing, iSTRIDE_lRezzing * _idx + iIDX_lRezzing_Pos)
#define yRezzingAdd(_name, _pos)   (lRezzing += [_name, _pos])
#define yRezzingRM(_idx)           (lRezzing = llDeleteSubList(lRezzing, _idx * iSTRIDE_lRezzing, _idx * iSTRIDE_lRezzing + iSTRIDE_lRezzing - 1))

list lRezzing = [];
// /


// timeout for dataserver events
//
#define fTIMER_TIMEOUT_DS          30.0



#endif  // _CORE
