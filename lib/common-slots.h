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
#define iSlots2SeatNo(_strideidx)       ((int)Endstr(sSlots2Seat(_strideidx), 4))


#ifdef DEBUG_ShowSlots
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
// 		opf("CSV:", llList2CSV(_l));
#else
#define DEBUG_virtualShowSlots(...)
#endif


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
#define iSeatNoToSlotNo(_n)        (LstIdx(slots, (sSEAT) + (string)(_n)) / (stride))

//
// / used in core
//


#endif  // _COMMON_SLOTS
