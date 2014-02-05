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
#define DEBUG3 0  //


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
#define stFACE_ENABLE             16
#define stIGNORE_RT_PERMS         32


// chatchannel depends on llGetKey(), should be optimized
//
integer chatchannel;



integer newprimcount;

// ?
integer primcount;

// use in for loops, should be local
//
integer seatcount;

// declared locally as well, purpose unknown
//
// integer stop;


// used to prevent receiving slot updates sent by self
//
key kMYKEY;

key thisAV;


// can probably be local
//
string currentanim;


// can probably be local
//
string lastAnimRunning;



list adjusters = [];
list avatarOffsets;  // agent uuid, vector offset
list faceTimes = [];
list faceanims;
list lastanim;
list slots;


// #define DEBUG_Showanimslist
#include <slave-animslist.h>


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

	// virtualinlinePrintSingleSlot(slots, slotNum);

	UnStatus(stFACE_ANIM_DOING);

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
		primcount = llGetNumberOfPrims();
		newprimcount = primcount;
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

						// Create a string with buttons for the menu from the slots list.
						// These buttons are used for changing seats.
						//
						{
							string buttonStr = "";
							int $_ = Len(slots) / stride;
							LoopDown($_,
								 key agent = kSlots2Ava($_);
								 if(agent)
									 {
										 buttonStr += concat(TruncateDialogButton(llGetUsername(agent)), ",");
									 }
								 else
									 {
										 buttonStr += concat(TruncateDialogButton(sSlots2Seat($_)), ",");
									 }
								 );

							//send list of buttons to the menu
							//
							// this should be done by the core and not here!
							//
							llMessageLinked(LINK_SET, iBUTTONUPDATE, buttonStr, NULL_KEY);
						}

						//we need a list consisting of sitter key followed by each face anim and the associated time of each
						// put face anims for each slot into a list
						{
							// DEBUG_virtualShowSlots(slots);

							UnStatus(stFACE_ANIM_GOT);
							faceTimes = [];

							int $_ = Len(slots) / stride;
							LoopDown($_,
								 if(kSlots2Ava($_))
									 {
										 if(sSlots2Facials($_))
											 {
												 list faceanimsTemp = llParseString2List(sSlots2Facials($_), ["~"], []);
												 DEBUGmsg0("face anims temp:", llList2CSV(faceanimsTemp));
												 list faces = [];
												 integer hasNewFaceTime = 0;
												 integer nFace = Len(faceanimsTemp);

												 LoopDown(nFace,
													  //parse this face anim for anim name and time
													  list temp = llParseString2List(llList2String(faceanimsTemp, nFace), ["="], []);
													  //time must be optional so we will make default a zero
													  //queue on zero to revert to older stuff
													  if(llList2String(temp, 1))
														  {
															  //collect the name of the anim and the time
															  faces += ([llList2String(temp, 0), llList2Integer(temp, 1)]);
															  hasNewFaceTime = 1;
														  }
													  else
														  {
															  faces += ([llList2String(temp, 0), -1]);
														  }
													  );

												 SetStatus(stFACE_ANIM_GOT);
												 //add sitter key and flag if timer defined followed by a stride 2 list containing face anim name and associated time
												 faceTimes += ([kSlots2Ava($_), hasNewFaceTime, Len(faceanimsTemp)] + faces);
												 DEBUGmsg0("adding to faceTimes:", llList2CSV([kSlots2Ava($_), hasNewFaceTime, Len(faceanimsTemp)] + faces));
											 }
									 }
								 );

							// DEBUG_virtualShowSlots(slots);

						}

						{
							// Once alls slots have been received, everyone is rotated and positioned,
							// and the face anims list has been created. Ask someone for perms to
							// initiate playing the facials.
							//
							// requesting perms from a prim yields a script error
							//
							key agent = llGetLinkKey(llGetNumberOfPrims());
							when(AgentIsHere(agent))
								{
									llRequestPermissions(agent, flagPERMS);
								}
						}

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

		// receive an update for a single slot and doSeats() for that slot
		//
		virtualReceiveSlotSingle(str, slots, num, id, kMYKEY, doSeats(Len(slots) / stride - 1));

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

		if(num == layerPose)
			{
				DEBUGmsg0("layer pose message rcvd:", str);

				key av = llList2Key(llParseString2List(str, ["/"], []), 0);

				if(!sits(av))
					{
						DEBUGmsg0(av, "is not sitting");
						return;
					}

				SetStatus(stIGNORE_RT_PERMS);
				llRequestPermissions(av, flagPERMS);
				UnStatus(stIGNORE_RT_PERMS);

				// Returns the key of the avatar that last granted or declined
				// permissions to the script.
				//
				// --> That can be anyone ...
				//
				if(llGetPermissionsKey() != av)
					{
						ERRORmsg("unexpected agent change");
						return;
					}

				// starting and stopping animations can only be done when permissions
				// have been granted
				//
				// Since agents not granting perms are unsat, it can be assumed that
				// the permission has been granted.
				//

				list tempList1 = llParseString2List(llList2String(llParseString2List(str, ["/"], []), 1), ["~"], []);
				integer n;  // instruction
				integer layerStop = llGetListLength(tempList1);


				for(n = 0; n < layerStop; ++n)
					{
						list tempList = llParseString2List(llList2String(tempList1, n), [","], []);

#define tmpCMD                     llList2String(tempList, 0)
#define tmpANIM                    llList2String(tempList, 1)

						string cmd = tmpCMD;

						if(cmd == "stopAll")
							{
								// see slave-animslist.h
								//
								inlineAnimsStopAll(av);
								return;
							}

						when(cmd == "stop")
							{
								DEBUGmsg1("stop single anim:", tmpANIM);
								llStopAnimation(tmpANIM);
							}
						else
							{
								when(cmd == "start")
									{
										DEBUGmsg1("start single anim:", tmpANIM);
										llStartAnimation(tmpANIM);
									}
								else
									{
										ERRORmsg("unknown cmd");
									}
							}
					}
#undef tmpCMD
#undef tmpANIM

				return;
			}  // num == LayerPose

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

		if(iTOGGLE_FACIALS == num)
			{
				bool on = (str == "on");
				CompStatus(stFACE_ENABLE, on);

				return;
			}

		if(num == iUNSIT)
			{
				llUnSit((key)str);

				return;
			}

		if(num == SYNC)
			{
				SetStatus(stDOSYNC);
				integer $_ = llGetListLength(slots) / 8;
				LoopDown($_, key agent = kSlots2Ava($_); if(agent) { llRequestPermissions(agent, flagPERMS); doSeats($_); });

				// after syncing is completed, unset the status
				//
				// Executing more code when explicitly syncing seems to be the only
				// purpose for this status.
				//
				UnStatus(stDOSYNC);

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

	event run_time_permissions(integer perm)
	{
		thisAV = llGetPermissionsKey();

		unless((llGetPermissions() & flagPERMS))
			{
				// message to self
				//
				// core will update slots list on unsit
				//
				// This is probably not sane due to design.
				//
				llMessageLinked(LINK_THIS, iUNSIT, (string)thisAV, NULL_KEY);
				return;
			}

		IfStatus(stIGNORE_RT_PERMS)
		{
			return;
		}
		ERRORmsg("runtime perms triggered");


		IfNStatus(stFACE_ANIM_DOING)
		{
			//get the current requested animation from list slots.
			integer avIndex = llListFindList(slots, [thisAV]);
			currentanim = llList2String(slots, avIndex - 4);
			//look for the default LL 'Sit' animation.  We must stop this animation if it is running. New Sitter!
			list animsRunning = llGetAnimationList(thisAV);
			integer indexx = llListFindList(animsRunning, [(key)"1a5fe8ac-a804-8a5d-7cbd-56bd83184568"]);
			//we also need to know the last animation running.  Not New Sitter!
			//lastanim is a 2 stride list [thisAV, last active animation name]
			//index thisAV as a string in the list and then we can find the last animation.
			integer thisAvIndex = llListFindList(lastanim, [(string)thisAV]);

			IfNStatus(stDOSYNC)
			{
				if(indexx != -1)
					{
						lastAnimRunning = "Sit";
						lastanim += [(string)thisAV, "Sit"];
					}

				if(thisAvIndex != -1)
					{
						lastAnimRunning = llList2String(lastanim, thisAvIndex + 1);
					}

				//now we know which animation to stop so go ahead and stop it.
				if(lastAnimRunning != "")
					{
						llStopAnimation(lastAnimRunning);
					}

				thisAvIndex = llListFindList(lastanim, [(string)thisAV]);
				//now that we have the name of the last animation running, we can update the list with current animation.
				lastanim = llListReplaceList(lastanim, [(string)thisAV, currentanim], thisAvIndex, thisAvIndex + 1);

				if(avIndex != -1)
					{
						llStartAnimation(currentanim);
					}
			}
			else
				{
					llStopAnimation(currentanim);
					llStartAnimation("sit");
					llSleep(0.05);
					llStopAnimation("sit");
					llStartAnimation(currentanim);
				}
		}

		//start timer if we have face anims for any slot
		IfStatus(stFACE_ANIM_GOT)
		{
			llSetTimerEvent(1.0);
			SetStatus(stFACE_ANIM_DOING);
		}
		else
			{
				llSetTimerEvent(0.0);
				UnStatus(stFACE_ANIM_DOING);
			}


		//check all the slots for next seated AV, call for next seated AV to move and animate.

		// Apparently this is what was intended here --- but what exactly means "next seated AV"?
		// This would have to go by seat numbers maybe, since there is no particular order to
		// the sitting agents other than their seat numbers as they are in the slots list.
		//
		int $_ = LstIdx(slots, thisAV);
		unless(iIsUndetermined($_))
			{
				$_ /= stride;
				while($_ < Len(slots))
					{
						++$_;
						if(kSlots2Ava($_))
							{
								if(kSlots2Ava($_) != thisAV)
									{
										llRequestPermissions(kSlots2Ava($_), flagPERMS);
										return;
									}
							}
					}
			}
		// /
	}

	timer()
		{
			IfNStatus(stFACE_ENABLE)
			{
				return;
			}

			integer n;
			integer stop = llGetListLength(slots) / 8;
			key av;
			integer facecount;
			integer faceindex;


			for(n = 0; n < stop; ++n)
				{
					//doing each seat
					av = (key)llList2String(slots, n * 8 + 4);
					faceindex = 0;
					//locate our stride in faceTimes list
					integer keyHasFacial = llListFindList(faceTimes, [av]);
					//get number of face anims for this seat
					integer newFaceTimeFlag = llList2Integer(faceTimes, keyHasFacial + 1);

					if(newFaceTimeFlag == 0)
						{
							//need to know if someone seated in this seat, if not we won't do any facials
							if(av != "")
								{
									faceanims = llParseString2List(llList2String(slots, n * 8 + 3), ["~"], []);
									facecount = llGetListLength(faceanims);

									if(facecount && sits(thisAV))  //modified cause face anims were being imposed after AV stands.
										{
											SetStatus(stFACE_ANIM_DOING);
											thisAV = llGetPermissionsKey();
											llRequestPermissions(av, flagPERMS);
										}
								}

							integer x;

							for(x = 0; x < facecount; ++x)
								{
									if(facecount > 0)
										{
											if(faceindex < facecount)
												{
													if(boolAvValidLinkNum(av))
														{
															llStartAnimation(llList2String(faceanims, faceindex));
														}
												}

											faceindex++;
										}
								}
						}
					else
						if(av != "")
							{
								//need to know if someone seated in this seat, if not we won't do any facials
								//do our stuff with defined facial times
								facecount = llList2Integer(faceTimes, keyHasFacial + 2);

								//if we have facial anims make sure we have permissions for this av
								if((facecount > 0) && sits(thisAV))    //modified cause face anims were being imposed after AV stands.
									{
										SetStatus(stFACE_ANIM_DOING);
										thisAV = llGetPermissionsKey();
										llRequestPermissions(av, flagPERMS);
									}

								integer x;

								for(x = 1; x <= facecount; ++x)
									{
										//non looping we check if anim has run long enough
										if(faceindex < facecount)
											{
												integer faceStride = keyHasFacial + 1 + (x * 2);
												string animName = llList2String(faceTimes, faceStride);

												if(llList2Integer(faceTimes, faceStride + 1) > 0)
													{
														faceTimes = llListReplaceList(faceTimes, [llList2Integer(faceTimes, faceStride + 1) - 1],
																	      faceStride + 1, faceStride + 1);
													}

												if(facecount > 0)
													{
														bool avln = boolAvValidLinkNum(av);
														if(avln && llList2Integer(faceTimes, faceStride + 1) > 0)
															{
																llStartAnimation(animName);
															}
														else
															if(avln != -1 && llList2Integer(faceTimes, faceStride + 1) == -1)
																{
																	llStartAnimation(animName);
																}

														faceindex++;
													}
											}
									}

							}
				}

			when((llGetNumberOfPrims() < 2) || (llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) == ZERO_VECTOR))
				{
					// nobody sits on object

					llSetTimerEvent(0.0);
					UnStatus(stFACE_ANIM_DOING);
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

	changed(integer change)
		{
			if(change & CHANGED_LINK)
				{
					integer newPrimCount1 = llGetNumberOfPrims();

					// Huh, how many prim counters are there?
					//
					newprimcount = newPrimCount1;

					if(newprimcount == primcount)
						{
							//no AV's seated so clear the lastanim list.  done so we can detect LL's default Sit when reseating.
							lastanim = [];
							currentanim = "";
							lastAnimRunning = "";
						}
				}
		}
}
