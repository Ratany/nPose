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


// This file provides defines to handle the slots list.  When
// DEBUG_ShowSlots is defined, DEBUG_virtualShowSlots(_l) becomes
// available, which is a virtual function to display the contents of
// the slots list.


#ifndef _COMMON_SLOTS
#define _COMMON_SLOTS


// animationName, position vector, rotation vector, facial anim name, seated AV key, SATMSG, NOTSATMSG, Seat#
//
#define SLOTIDX_pose               0
#define SLOTIDX_position           1
#define SLOTIDX_rot                2
#define SLOTIDX_facial             3
#define SLOTIDX_agent              4
#define SLOTIDX_satmsg             5
#define SLOTIDX_notsat             6
#define SLOTIDX_seatno             7


#define sSlots2Pose(_strideidx)         llList2String   (slots, SLOTIDX_pose     + stride * (_strideidx))
#define vSlots2Position(_strideidx)     ForceList2Vector(slots, SLOTIDX_position + stride * (_strideidx))
#define rSlots2Rot(_strideidx)          ForceList2Rot   (slots, SLOTIDX_rot      + stride * (_strideidx))
#define sSlots2Facials(_strideidx)      llList2String   (slots, SLOTIDX_facial   + stride * (_strideidx))
#define kSlots2Ava(_strideidx)          llList2Key      (slots, SLOTIDX_agent    + stride * (_strideidx))
#define sSlots2Satmsg(_strideidx)       llList2String   (slots, SLOTIDX_satmsg   + stride * (_strideidx))
#define sSlots2Notsat(_strideidx)       llList2String   (slots, SLOTIDX_notsat   + stride * (_strideidx))
#define sSlots2Seat(_strideidx)         llList2String   (slots, SLOTIDX_seatno   + stride * (_strideidx))

// same as sSlots2Seat(), for any list specified in params
//
#define sSomeSlots2Seat(_l, _strideidx) llList2String   (_l, SLOTIDX_seatno   + stride * (_strideidx))

#define iSlots2SeatNo(_strideidx)       ((int)Endstr(sSlots2Seat(_strideidx), 4))


#define sToSlotsPose(_l, _strideidx)         llList2String   (_l, SLOTIDX_pose     + stride * (_strideidx))
#define vToSlotsPosition(_l, _strideidx)     ForceList2Vector(_l, SLOTIDX_position + stride * (_strideidx))
#define rToSlotsRot(_l, _strideidx)          ForceList2Rot   (_l, SLOTIDX_rot      + stride * (_strideidx))
#define sToSlotsFacials(_l, _strideidx)      llList2String   (_l, SLOTIDX_facial   + stride * (_strideidx))
#define kToSlotsAva(_l, _strideidx)          llList2Key      (_l, SLOTIDX_agent    + stride * (_strideidx))
#define sToSlotsSatmsg(_l, _strideidx)       llList2String   (_l, SLOTIDX_satmsg   + stride * (_strideidx))
#define sToSlotsNotsat(_l, _strideidx)       llList2String   (_l, SLOTIDX_notsat   + stride * (_strideidx))
#define sToSlotsSeat(_l, _strideidx)         llList2String   (_l, SLOTIDX_seatno   + stride * (_strideidx))




#define virtualinlinePrintSingleSlot(_list, _slotnum)			\
	DEBUGmsg("---------- stride:", _slotnum, "of", Len(_list) / stride, "----------"); \
	opf("pose:", sSlots2Pose(_slotnum));				\
	opf("pos :", vSlots2Position(_slotnum));			\
	opf("rot :", rSlots2Rot(_slotnum));				\
	opf("face:", sSlots2Facials(_slotnum));				\
	opf("ava :", kSlots2Ava(_slotnum));				\
	opf("sat :", sSlots2Satmsg(_slotnum));				\
	opf("not :", sSlots2Notsat(_slotnum));				\
	opf("seat:", sSlots2Seat(_slotnum))



#ifdef DEBUG_ShowSlots
#ifdef DEBUG_ShowSlots_Sittersonly
#define DEBUG_virtualShowSlots(_l)					\
	{								\
		int $_ = Len(_l) / stride;				\
		LoopDown($_,						\
			 if(kSlots2Ava($_))				\
				 {					\
					 virtualinlinePrintSingleSlot(_l, $_); \
				 }					\
			 );						\
									\
		if(Onlst(_l, llGetOwner()))				\
			{						\
				opf("\towner on list");			\
			}						\
		else							\
			{						\
				opf("\towner NOT on list");		\
			}						\
	}

#else

#define DEBUG_virtualShowSlots(_l)					\
	{								\
		int $_ = Len(_l) / stride;				\
		LoopDown($_,						\
			 DEBUGmsg("---------- stride:", $_, "of", Len(_l) / stride, "----------"); \
			 opf("pose:", sSlots2Pose($_));			\
			 opf("pos :", vSlots2Position($_));		\
			 opf("rot :", rSlots2Rot($_));			\
			 opf("face:", sSlots2Facials($_));		\
			 opf("ava :", kSlots2Ava($_));			\
			 opf("sat :", sSlots2Satmsg($_));		\
			 opf("not :", sSlots2Notsat($_));		\
			 opf("seat:", sSlots2Seat($_))			\
			 );						\
									\
		if(Onlst(_l, llGetOwner()))				\
			{						\
				opf("\towner on list");			\
			}						\
		else							\
			{						\
				opf("\towner NOT on list");		\
			}						\
	}
#endif  // DEBUG_ShowSlots_Sittersonly
#else  // DEBUG_ShowSlots
#define DEBUG_virtualShowSlots(...)
#endif  // DEBUG_ShowSlots


// used in core
//

// LSL is too retarded to convert a string to a vector when the string
// is on a list.  This must be expensively forced :((
//
#define ForceList2Vector(_l, _n)   ((vector)llList2String(_l, _n))
//
// same bug goes for rotations :((
//
#define ForceList2Rot(_l, _n)      ((rotation)llList2String(_l, _n))

// convert a seat number to a slot number (slot number means index to
// the begin of the stride in the slots list the seat with the given
// number is an item of)
//
// #define iSeatNoToSlotNo(_n)        (LstIdx(slots, (sSEAT) + (string)(_n)) / (stride))

//
// / used in core
//


// Convert a stride of a slots list to a stride of a slots list to get
// the data types right.  Requires lots of memory ...
//
#define ySlotsConvertStride(_lsrc, _strideofsrc, _ldest, _strideofdest)	\
	(_ldest = llListReplaceList(_ldest,				\
				    [					\
				     sToSlotsPose(_lsrc, _strideofsrc),	\
				     vToSlotsPosition(_lsrc, _strideofsrc), \
				     rToSlotsRot(_lsrc, _strideofsrc),	\
				     sToSlotsFacials(_lsrc, _strideofsrc), \
				     kToSlotsAva(_lsrc, _strideofsrc),	\
				     sToSlotsSatmsg(_lsrc, _strideofsrc), \
				     sToSlotsNotsat(_lsrc, _strideofsrc), \
				     sToSlotsSeat(_lsrc, _strideofsrc)	\
									], \
				    _strideofdest, (_strideofdest) + stride - 1))

// Add stride 0 from a list _lsrc to a list _ldest.  Both lists are
// slots lists.
//
#define ySlotsAddStride(_lsrc, _ldest)					\
	(_ldest += [							\
		    sToSlotsPose(_lsrc, 0),				\
		    vToSlotsPosition(_lsrc, 0),				\
		    rToSlotsRot(_lsrc, 0),				\
		    sToSlotsFacials(_lsrc, 0),				\
		    kToSlotsAva(_lsrc, 0),				\
		    sToSlotsSatmsg(_lsrc, 0),				\
		    sToSlotsNotsat(_lsrc, 0),				\
		    sToSlotsSeat(_lsrc, 0)				\
									])

// get a copy of one slot-stride
//
#define ySlotsStridecopy(_lsrc, _slotnum)    llList2List(_lsrc, (_slotnum) * stride, (_slotnum) * stride + stride - 1)


// delete one slot-stride
//
#define ySlotsStrideDelete(_l, _slotnum)     (_l = llDeleteSubList(_l, (_slotnum) * stride, (_slotnum) * stride + stride - 1))


// Sending the slots list in one piece is a problem for all recipients.
// Recipients get a long string and have no choice but to parse it
// into a list from which the slots list is created as a copy.  Simply
// parsing the string into a slots list and then converting that list
// to get the data types right takes about 21kB for 30 slots.
// Maintaining a duplicate of the list takes about four times as much
// memory as the length of the string to build the lists because two
// copies must be used, and building a list takes about two times the
// memory the final list takes.
//
// Hence send the slots list one slot after the other instead of the
// whole list in one piece.  All recipients should be updated to
// receive the slots list slot by slot --- until then, use the current
// method, and additionally send slot after slot.
//
// To send the slots list, use 'virtualSendSlotUpdate(slots);'.


// link number to send the slots list to
//
#define lnSLOTS_RCVR               LINK_THIS

// number to identify the type of message
//
// update of whole slots list
//
#define iSLOTINFO_ALL              16384


// number to identify the type of message
//
// update of ONE STRIDE of the slots list
//
#define iSLOTINFO_SINGLE           16385


// protocol: identifier for starting a sequence
//
// must be 8 characters
//
#define protSLOTINFO_start         "sltstart"


// protocol: identifier for end of sequence
//
// Receivers must not operate with an incomplete slots list, so this
// message indicates the end of the sequence started with
// protSLOTINFO_start.
//
// must be 8 characters
//
#define protSLOTINFO_end           "slotsend"


// send a full slots update, whole list, one slot after the other
//
#define virtualSendSlotUpdate(_l, _senderkey)				\
	{								\
		llMessageLinked(lnSLOTS_RCVR, iSLOTINFO_ALL, protSLOTINFO_start, _senderkey); \
		int $_ = Len(_l) / stride;				\
		LoopDown($_,						\
			 DEBUGmsg3("sending slot:", llDumpList2String(llList2List(_l, $_ * stride, $_ * stride + stride - 1), "^")); \
			 llMessageLinked(lnSLOTS_RCVR, iSLOTINFO_ALL, llDumpList2String(llList2List(_l, $_ * stride, $_ * stride + stride - 1), "^"), _senderkey) \
			 );						\
		llMessageLinked(lnSLOTS_RCVR, iSLOTINFO_ALL, protSLOTINFO_end, _senderkey); \
	}

// seatupdate disabled
//
// This seat update, when in virtualSendSlotUpdate(), leads to about
// 6500 bytes blocked in the core by delayed garbage collection with
// 33 slots.
//
// 		llMessageLinked(lnSLOTS_RCVR, seatupdate, llDumpList2String(_l, "^"), _senderkey);
//

// virtualSendSlotSingle() and virtualReceiveSlotSingle() are for the
// update of a single slot only!  To update the whole list, use
// virtualSendSlotUpdate()!
//
//
// send a single slot as update
//
// _senderkey must be used to prevent scripts from acting on slot
// updates they sent themselves!
//
#define virtualSendSlotSingle(_lsrc, _slotnum, _senderkey)		\
	llMessageLinked(lnSLOTS_RCVR, iSLOTINFO_SINGLE, llDumpList2String(llList2List(_lsrc, (_slotnum) * stride, (_slotnum) * stride + stride - 1), "^"), _senderkey)
//
//
// receive an update for a single slot
//
// goes into the linked_message() event as is
// requires that seat numbers are uniq
//
// _senderkey must be used to prevent scripts from acting on slot
// updates they sent themselves!
//
#define virtualReceiveSlotSingle(_sfrom, _ldest, $_i, _senderkey, _mykey, _do) \
	if(iSLOTINFO_SINGLE == ($_i))					\
		{							\
			if(_mykey != _senderkey)			\
				{					\
					list $_l = llParseStringKeepNulls(_sfrom, ["^"], []); \
					int $_slotnum = LstIdx(_ldest, sSomeSlots2Seat($_l, 0)); \
					unless(iIsUndetermined($_slotnum)) \
						{			\
							$_slotnum /= stride; \
							ySlotsStrideDelete(_ldest, $_slotnum); \
							ySlotsAddStride($_l, _ldest); \
							_do;		\
						}			\
					else				\
						{			\
							ERRORmsg("undetermined slotupdate"); \
						}			\
				}					\
									\
			return;						\
		}



#endif  // _COMMON_SLOTS
