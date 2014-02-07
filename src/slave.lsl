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


#define DEBUG0 0  // anims, seatupdate
#define DEBUG1 0  // stopping anims
#define DEBUG2 0  // stopping anims
#define DEBUG3 0  // doSeats()


// #define _STD_DEBUG_USE_TIME
// #define _STD_DEBUG_PUBLIC
// #define DEBUG_ShowSlots
// #define DEBUG_ShowSlots_Sittersonly


#include <lslstddef.h>
#include <undetermined.h>

#include <avn/slave.h>


#include <common-slots.h>

#include <constants.h>

#include <sitting.h>


int status = 0;
#define stDOSYNC                   1
#define stFACE_ANIM_DOING          2
#define stFACE_ANIM_GOT            4
#define stSLOTS_RCV                8
#define stIGNORE_RT_PERMS         32


// chatchannel depends on llGetKey(), should be optimized
//
integer chatchannel;


// used to prevent receiving slot updates sent by self
//
key kMYKEY;

key thisAV;




list adjusters = [];
list avatarOffsets = [];  // agent uuid, vector offset
list slots;




#define flagPERMS                  (PERMISSION_TRIGGER_ANIMATION)

#define boolAvValidLinkNum(_agent) (!(AvLinkNum(_agent) < 0))


// should be inlined
//
integer AvLinkNum(key av)
{
	integer linkcount = llGetNumberOfPrims();

	key k = llGetLinkKey(linkcount);
	while((k != av) && (llGetAgentSize((k = llGetLinkKey(linkcount))) != ZERO_VECTOR))
		{
			--linkcount;
		}

	return (linkcount * ((k == av) - (k != av)));
}
// (put into getlinknumbers.lsl)


void doSeats(integer slotNum)
{
	key avKey = kSlots2Ava(slotNum);
	int avlinknum = AvLinkNum(avKey);
	when((avlinknum < 0) || (avKey == NULL_KEY))
		{
			return;
		}

	//
	// Position and rotate the sitting agents according to
	// slots list and apparently to their personal offset.
	//

	integer avinoffsets = LstIdx(avatarOffsets, kSlots2Ava(slotNum));
	vector agentpos = vSlots2Position(slotNum);

	if(!iIsUndetermined(avinoffsets))
		{
			// add personal offset to agent position from slots list
			//
			agentpos += llList2Vector(avatarOffsets, avinoffsets + 1) * rSlots2Rot(slotNum);
		}

	rotation agentrot = rSlots2Rot(slotNum);
	vector size = llGetAgentSize(avKey);

	rotation localrot = ZERO_ROTATION;
	vector localpos = ZERO_VECTOR;

	if(llGetLinkNumber() > 1)
		{
			// use local rotation of the prim the script is in unless it´s the root prim
			//
			// This is probably bad because it screws up all adjustments when the script
			// is moved from the root prim into another one?
			//
			// The root prim has a global rotation the local rotation is relative to, and
			// the rotation of the root prim might _not_ be a ZERO_ROTATION as assumed above.
			//
			// Perhaps this needs to be 'llGetLocalRot() / llGetRootRotation()'.  Same goes
			// for the position.
			//
			// Why are these global coordinates and rotations anyway, rather than positioning
			// all agents always relative to the root prim, which seems to be much simpler?
			//
			localrot = llGetLocalRot();
			localpos = llGetLocalPos();
		}

	agentpos.z += 0.4;
	SLPPF(avlinknum, [PRIM_POSITION, ((agentpos - (llRot2Up(agentrot) * size.z * 0.02638)) * localrot) + localpos, PRIM_ROTATION, agentrot * localrot / llGetRootRotation()]);

#if DEBUG3
	DEBUGmsg3("pos:", ((agentpos - (llRot2Up(agentrot) * size.z * 0.02638)) * localrot) + localpos, "rot:", agentrot * localrot / llGetRootRotation());
	virtualinlinePrintSingleSlot(slots, slotNum);
#endif
}


// add a new stride when agent is not found in the list, otherwise
// increase the offset in the list by given offset unless given offset
// is ZERO_VECTOR, in which case the offset in the list is replaced
// with ZERO_VECTOR
//
#define inlineSetAvatarOffset(avatar, offset)				\
	integer avatarOffsetsIndex = LstIdx(avatarOffsets, avatar);	\
									\
	when(iIsUndetermined(avatarOffsetsIndex))			\
	{								\
		avatarOffsets += [avatar, offset];			\
									\
		return;							\
	}								\
									\
	if(offset)							\
		{							\
			offset += llList2Vector(avatarOffsets, avatarOffsetsIndex + 1);	\
		}							\
									\
	avatarOffsets = llListReplaceList(avatarOffsets, [offset], avatarOffsetsIndex, avatarOffsetsIndex)


#define RezNextAdjuster()						\
	llRezObject("Adjuster", llGetPos() + <0, 0, 1>, ZERO_VECTOR, llGetRot(), chatchannel)


#define ChatAdjusterPos(slotnum)					\
	{								\
		rotation rot = llGetRot();				\
		integer index = (slotnum) * stride;			\
		vector pos = llGetPos() + llList2Vector(slots, index + 1) * rot; \
		rot = llList2Rot(slots, index + 2) * rot;		\
		string out = llList2String(adjusters, slotnum) + "|posrot|" + (string)pos + "|" + (string)rot; \
		llRegionSay(chatchannel, out);				\
	}


default
{
	event state_entry()
	{
		afootell(concat(concat(llGetScriptName(), " "), VERSION));

		kMYKEY = llGenerateKey();

		llMessageLinked(LINK_SET, SEND_CHATCHANNEL, "", "");
	}

	event link_message(integer sender, integer num, string str, key id)
	{
		if((iSLOTINFO_ALL == num) && (id != kMYKEY))
			{
				// process transfer of slots list
				//
				
				when(NotStatus(stSLOTS_RCV) && (protSLOTINFO_start == str))
					{
						//
						// a sequence of slots will be received
						//
						DEBUGmsg0("rcv slots start");

						slots = [];
						SetStatus(stSLOTS_RCV);
						return;
					}

				when(HasStatus(stSLOTS_RCV) && (protSLOTINFO_end == str))
					{
						//
						// transmission of a sequence of slots has been completed
						//
						DEBUGmsg0("rcv slots end");

						UnStatus(stSLOTS_RCV);

						// tell the menu to update all buttons
						//
						llMessageLinked(LINK_SET, iBUTTONUPDATE, "", NULL_KEY);

						return;
					}

				// order does matter for setting the status!
				//
				IfStatus(stSLOTS_RCV)
				{
					//
					// Receiving slots is ongoing, and another slot has been received.
					//
					list thisslot = llParseStringKeepNulls(str, ["^"], []);

					DEBUGmsg0("rcv a slot:", str);
					ySlotsAddStride(thisslot, slots);

					// position and rotate agent when a new slot has been received, same
					// as with receiving a single slot
					//
					doSeats(Len(slots) / stride - 1);

					return;
				}

				ERRORmsg("protocol violation");
				return;
			}  // seatupdate

		// receive an update for a single slot and doSeats() for that slot,
		// tell menu to update buttons
		//
		virtualReceiveSlotSingle(str, slots, num, id, kMYKEY, doSeats(Len(slots) / stride - 1); llMessageLinked(LINK_SET, iBUTTONUPDATE, "", NULL_KEY));

		if(num == seatupdate)
			{
				ERRORmsg("method not supported");
				return;
			}

		if(num == iRCV_CHATCHANNEL)    //got chatchannel from the core.
			{
				chatchannel = (integer)str;
				DEBUGmsg0("chat channel:", chatchannel);
				return;
			}

		if((num == ADJUSTOFFSET) || (num == SETOFFSET))
			{
				vector $_ = (vector)str;
				inlineSetAvatarOffset(id, $_);

				int index = LstIdx(slots, id);
				unless(iIsUndetermined(index))
					{
						// Send only the one slot that has actually changed.
						//
						index /= stride;
						virtualSendSlotSingle(slots, index, kMYKEY);

						// reposition the agent
						//
						doSeats(index);
					}

				return;
			}

		if(num == iUNSIT)
			{
				llUnSit((key)str);

				return;
			}


		if(num == ADJUST)   //adjust has been chosen from the menu
			{
				llSay(chatchannel, "adjuster_die");
				adjusters = [];

				if(llGetInventoryType("Adjuster") & INVENTORY_OBJECT)
					{
						RezNextAdjuster();
					}
				else
					{
						llRegionSayTo(llGetOwner(), 0, "Seat Adjustment disabled.  No Adjuster object found in" + llGetObjectName() + ".");
					}

				return;
			}

		if(num == STOPADJUST)   //stopadjust has been chosen from the menu
			{
				llMessageLinked(LINK_SET, 204, "", "");
				llSay(chatchannel, "adjuster_die");
				adjusters = [];

				return;
			}

		if(iADJUST_UPDATE_ADJUSTERS(num, str))      //got a new pose so update adjusters.
			{
				adjusters = [];
				RezNextAdjuster();

				return;
			}

		// this is being relayed from the core
		//
		if(num == iADJUST_UPDATE)      //heard from an adjuster so a new position must be used, upate slots and chat out new position.
			{
				integer index = llListFindList(adjusters, [id]);

				unless(iIsUndetermined(index))
					{
						// get new adjustment from what the adjuster says, position and rotation
						//
						list params = llParseString2List(str, ["|"], []);

						vector newpos = ForceList2Vector(params, 0) - llGetPos();
						newpos /= llGetRot();

						rotation newrot = ForceList2Rot(params, 1) / llGetRot();
						// /

						// make a copy of the slot, replace old adjustment with new adjustment
						//
						list stridecopy = ySlotsStridecopy(slots, index);
						ySlotsStrideDelete(slots, index);

						stridecopy = llListReplaceList(stridecopy, [newpos, newrot], SLOTIDX_position, SLOTIDX_rot);
						ySlotsAddStride(stridecopy, slots);
						// /

						// show what´s in the slot being adjusted
						//
						virtualinlinePrintSingleSlot(slots, index);

						// Send only the one slot that has actually changed.
						//
						virtualSendSlotSingle(slots, index, kMYKEY);

						// reposition the agent
						//
						doSeats(index);

						//
						// THE MENU-VIC MIGHT NEEDS THE UPDATE, TOO --- HAVE TO LOOK INTO THAT LATER
						//
					}

				return;
			}
		// /

		if(num == DUMP)
			{
				integer n = Len(slots) / stride;
				LoopDown(n, sprintlt("ANIM", sSlots2Pose(n), vSlots2Position(n), llRot2Euler(rSlots2Rot(n)) * RAD_TO_DEG, sSlots2Facials(n)));

				llRegionSay(chatchannel, "posdump");

				return;
			}

		if(num == memusage)
			{
				MemTell;
			}
	}

	object_rez(key id)
		{
			if(llKey2Name(id) == "Adjuster")
				{
					adjusters += [id];
					integer adjLen = llGetListLength(adjusters);
					ChatAdjusterPos(adjLen - 1);

					if(adjLen < (llGetListLength(slots) / 8))
						{
							RezNextAdjuster();
						}
				}
		}
}
