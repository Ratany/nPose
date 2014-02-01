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
// or can optionally be inlined.


#ifndef _CORE_INLINE
#define _CORE_INLINE


// when no slot is free, returns < 0 when inlined, -1 when not inlined
//
// define this to inline FindEmptySlot()
//
#define _INLINE_FindEmptySlot


// define this to use the function sits() instead of an inlined version
//
#define _OUTLINE_virtualboolIsSitting


// inlines SwapTwoSlots()
//
#define _INLINE_SwapTwoSlots


///////////////////////////////////////////////////////////////////////////
//
// inlined parts start below
//
///////////////////////////////////////////////////////////////////////////




// see whether agent _k is sitting on object or not
//
// saves creating a list of all agents in assignSlots()
//
#define virtualboolIsSitting(_k, _bool)					\
	{								\
		int $_ = llGetNumberOfPrims();				\
		_bool = $_;						\
		while($_ && !(_bool = !(llGetLinkKey($_) != (_k))) && boolIsAgent(llGetLinkKey($_))) \
			{						\
				--$_;					\
			}						\
	}


// might save memory to have this as a function
//
#ifdef _OUTLINE_virtualboolIsSitting
bool sits(key k)
{
	bool b;
	virtualboolIsSitting(k, b);
	return b;
}
#endif


#define str_replace(str, search, replace)         llDumpList2String(llParseStringKeepNulls(str, [search], []), replace)


#ifdef _INLINE_FindEmptySlot
//
// FindEmptySlot(): this function is not ideal for inlining
//
// return < 0 when no slot is free rather than -1
//
#define FindEmptySlot(_ret)						\
	_ret = 0;							\
	while((_ret < slotMax) && (llList2String(slots, _ret * (stride) + 4) != "")) \
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
			if(llList2String(slots, n * stride + 4) == "")
				{
					return n;
				}
			++n;
		}

	return -1;
}
#endif


#ifdef _INLINE_SwapTwoSlots

// SwapTwoSlots() can optionally be inlined

#define SwapTwoSlots(currentseatnum, newseatnum)			\
	int OldSlot = iSeatNoToSlotNo((currentseatnum));		\
	int NewSlot = iSeatNoToSlotNo((newseatnum));			\
									\
	when((OldSlot != NewSlot) && !boolInvalidSlotNo(OldSlot) && !boolInvalidSlotNo(NewSlot)) \
	{								\
		key oldslotagent = kSlots2Ava(OldSlot);			\
		OldSlot *= stride;					\
		OldSlot += SLOTIDX_agent;				\
		slots = llListReplaceList(slots, [kSlots2Ava(NewSlot)], OldSlot, OldSlot); \
									\
		NewSlot *= stride;					\
		NewSlot += SLOTIDX_agent;				\
		slots = llListReplaceList(slots, [oldslotagent], NewSlot, NewSlot); \
		llMessageLinked(LINK_SET, seatupdate, llDumpList2String(slots, "^"), NULL_KEY);	\
	}

#else

void SwapTwoSlots(integer currentseatnum, integer newseatnum)
{
	int OldSlot = iSeatNoToSlotNo(currentseatnum);
	int NewSlot = iSeatNoToSlotNo(newseatnum);

	when((OldSlot != NewSlot) && !boolInvalidSlotNo(OldSlot) && !boolInvalidSlotNo(NewSlot))
		{
			// put the new agent into the old slot
			//
			key oldslotagent = kSlots2Ava(OldSlot);
			OldSlot *= stride;
			OldSlot += SLOTIDX_agent;
			slots = llListReplaceList(slots, [kSlots2Ava(NewSlot)], OldSlot, OldSlot);

			// put the old agent into the new slot
			//
			NewSlot *= stride;
			NewSlot += SLOTIDX_agent;
			slots = llListReplaceList(slots, [oldslotagent], NewSlot, NewSlot);
			llMessageLinked(LINK_SET, seatupdate, llDumpList2String(slots, "^"), NULL_KEY);
		}
}
#endif  // _INLINE_SwapTwoSlots

// old version would use the last seat for swapping when the agent
// does not have a slot assigned, and the code indicates that this is
// not intended
//
// new version does not swap when the agent does not have a slot
// assigned or when the seat number is out of bounds
//
#define SwapAvatarInto(avatar, newseat)					\
	int idx = LstIdx(slots, (avatar)) / (stride);			\
									\
	unless(boolInvalidSlotNo(idx))					\
	{								\
		SwapTwoSlots(iSlots2SeatNo(idx), (newseat));		\
	}

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
