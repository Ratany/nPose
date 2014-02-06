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


// This file contains functions from core.lsl which have been inlined
// or can optionally be inlined.  Inlining may use more or less script
// memory, so test.


#ifndef _CORE_INLINE
#define _CORE_INLINE


// when no slot is free, returns < 0 when inlined, -1 when not inlined
//
// define this to inline FindEmptySlot()
//
#define _INLINE_FindEmptySlot



///////////////////////////////////////////////////////////////////////////
//
// inlined parts start below
//
///////////////////////////////////////////////////////////////////////////


#define str_replace(str, search, replace)         llDumpList2String(llParseStringKeepNulls(str, [search], []), replace)


#ifdef _INLINE_FindEmptySlot
//
// FindEmptySlot(): this function is not ideal for inlining
//
// return < 0 when no slot is free rather than -1
//
#define FindEmptySlot(_ret)						\
	_ret = 0;							\
	while((_ret < slotMax) && (kSlots2Ava(_ret) != ""))		\
		{							\
			++_ret;					\
		}							\
	_ret = _ret * ((_ret != slotMax) - (_ret == slotMax)) - !slotMax

#else

integer FindEmptySlot()
{
	int n = 0;
	while(n < slotMax)
		{
			if(kSlots2Ava(n) == "")
				{
					return n;
				}
			++n;
		}

	return -1;
}
#endif


#define ReadCard()							\
		lastStrideCount = slotMax;				\
		slotMax = 0;						\
		llRegionSay(chatchannel, "die");			\
		llRegionSay(chatchannel, "adjuster_die");		\
		line = 0;						\
									\
		if(llGetInventoryKey(card))				\
			{						\
				DEBUGmsg0("attempting to read card: '", card, "'", "uuid:", llGetInventoryKey(card), "line:", line); \
									\
				dataid = llGetNotecardLine(card, line);	\
			}



#endif  // _CORE_INLINE
