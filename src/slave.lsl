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
#define DEBUG_ShowSlots
#define DEBUG_ShowSlots_Sittersonly


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


// chatchannel depends on llGetKey(), should be optimized
//
integer chatchannel;



integer newprimcount;

// must be initialized
//
integer nextAvatarOffset = 0;

// ?
integer primcount;

// use in for loops, should be local
//
integer seatcount;

// declared locally as well, purpose unknown
//
integer stop;



key thisAV;


// can probably be local
//
string currentanim;

// might be a status
//
string facialEnable = "on";

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


// MoveLinkedAv(), inlined saves over 1056 byes
//
// does not work when the root prim is not linked?
//
// This is now part of doSeats()!
//
#define inlineMoveLinkedAv(linknum, avpos, avrot)			\
	int avlinknum = AvLinkNum(avKey);				\
	unless(avlinknum < 0)						\
	{								\
		vector size = llGetAgentSize(avKey);			\
									\
		rotation localrot = ZERO_ROTATION;			\
		vector localpos = ZERO_VECTOR;				\
									\
		if(llGetLinkNumber() > 1)				\
			{						\
				localrot = llGetLocalRot();		\
				localpos = llGetLocalPos();		\
			}						\
									\
		avpos.z += 0.4;						\
		SLPPF(linknum, [PRIM_POSITION, ((avpos - (llRot2Up(avrot) * size.z * 0.02638)) * localrot) + localpos, PRIM_ROTATION, (avrot) * localrot / llGetRootRotation()]); \
	}


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


#define inlineAppliedOffsets(n)						\
	integer avinoffsets = LstIdx(avatarOffsets, kSlots2Ava(n));	\
	vector vpos = vSlots2Position(n);				\
									\
	if(!iIsUndetermined(avinoffsets))				\
		{							\
			vpos += llList2Vector(avatarOffsets, avinoffsets + 1) * rSlots2Rot(n); \
		}


void doSeats(integer slotNum, key avKey)
{
	// DEBUG_virtualShowSlots(slots);

	//
	// should check whether agent is sitting or not?
	//
	// When agent is not sitting, their link number is
	// undetermined.  To implement check, get link number first,
	// so modify inlineAppliedOffsets().
	//

	when(avKey)
	{
		UnStatus(stFACE_ANIM_DOING);

		// ouch?
		//
		stop = llGetListLength(slots) / 8;

		llRequestPermissions(avKey, PERMISSION_TRIGGER_ANIMATION);

		IfNStatus(stDOSYNC)
		{
			inlineAppliedOffsets(slotNum);
			inlineMoveLinkedAv(avlinknum, vpos, llList2Rot(slots, ((slotNum) * 8) + 2));
		}
	}
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
		nextAvatarOffset += 2;					\
	}								\
	else								\
		{							\
									\
			if(offset)					\
				{					\
					offset += llList2Vector(avatarOffsets, avatarOffsetsIndex + 1);	\
				}					\
									\
			avatarOffsets = llListReplaceList(avatarOffsets, [offset], avatarOffsetsIndex, avatarOffsetsIndex); \
		}
// can probably return rather than use else once concatenated if/elses are fixed



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

			llMessageLinked(LINK_SET, SEND_CHATCHANNEL, "", "");
			primcount = llGetNumberOfPrims();
			newprimcount = primcount;
		}

	event link_message(integer sender, integer num, string str, key id)
	{
		if(iSLOTINFO == num)
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
							llMessageLinked(LINK_SET, seatupdate + 1, buttonStr, NULL_KEY);
						}

						//we need a list consisting of sitter key followed by each face anim and the associated time of each
						// put face anims for each slot into a list
						{
							DEBUG_virtualShowSlots(slots);

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

							DEBUG_virtualShowSlots(slots);

						}

						//we have our new list of AV's and positions so put them where they belong.  fire off the first seated AV and run time will do the rest.
						{
							int $_ = Len(slots) / stride;
							LoopDown($_,
								 key agent = kSlots2Ava($_);
								 if(agent)
									 {
										 if(sits(agent))
											 {
												 UnStatus(stDOSYNC);

												 // doSeats() triggers runtimeperms-event by requesting perms
												 //
												 doSeats(seatcount, agent);
												 return;
											 }
									 }
								 );
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

					return;
				}

				ERRORmsg("protocol violation");
				return;
			}  // seatupdate

		if(num == 1)    //got chatchannel from the core.
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

				llRequestPermissions(av, PERMISSION_TRIGGER_ANIMATION);

				// Returns the key of the avatar that last granted or declined
				// permissions to the script.
				//
				// --> That can be anyone ...
				//
				// av = llGetPermissionsKey();
				if(llGetPermissionsKey() != av)
					{
						ERRORmsg("unexpected agent change");
						return;
					}

				// starting and stopping animations can only be done when permissions
				// have been granted
				//
				bool hasperms = (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION);

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
								when(hasperms)
								{
									DEBUGmsg1("stop single anim:", tmpANIM);
									llStopAnimation(tmpANIM);
								}
								else
									{
										ERRORmsg("missing perms");
									}
							}
						else
							{
								when(cmd == "start")
									{
										when(hasperms)
										{
											DEBUGmsg1("start single anim:", tmpANIM);
											llStartAnimation(tmpANIM);
										}
										else
											{
												ERRORmsg("missing perms");
											}
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
				llMessageLinked(LINK_SET, seatupdate, llDumpList2String(slots, "^"), NULL_KEY);

				return;
			}

		if(num == -241)
			{
				facialEnable = str;

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
				integer stop = llGetListLength(slots) / 8;

				for(seatcount = 0; seatcount < stop; ++seatcount)
					{
						doSeats(seatcount, llList2String(slots, (seatcount) * 8 + 4));
						return;
					}

				return;
			}

		if(num == 201)   //adjust has been chosen from the menu
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

		if(num == 205)   //stopadjust has been chosen from the menu
			{
				llMessageLinked(LINK_SET, 204, "", "");
				llSay(chatchannel, "adjuster_die");
				adjusters = [];

				return;
			}

		if(num == 2 && str == "RezAdjuster")      //got a new pose so update adjusters.
			{
				adjusters = [];
				RezNextAdjuster();

				return;
			}

		if(num == 3)      //heard from an adjuster so a new position must be used, upate slots and chat out new position.
			{
				integer index = llListFindList(adjusters, [id]);

				if(index != -1)
					{
						string primName = llGetObjectName();
						llSetObjectName(llGetLinkName(1));
						list params = llParseString2List(str, ["|"], []);
						vector newpos = (vector)llList2String(params, 0) - llGetPos();
						newpos = newpos / llGetRot();
						integer slotsindex = index * stride;
						rotation newrot = (rotation)llList2String(params, 1) / llGetRot();
						slots = llListReplaceList(slots, [newpos, newrot], slotsindex + 1, slotsindex + 2);
						llRegionSayTo(llGetOwner(), 0, "\nANIM|" + llList2String(slots, slotsindex) + "|" + (string)newpos + "|" +
							      (string)(llRot2Euler(newrot) * RAD_TO_DEG) + "|" + llList2String(slots, slotsindex + 3));
						llSetObjectName(primName);
						llMessageLinked(LINK_SET, seatupdate, llDumpList2String(slots, "^"), NULL_KEY);
						//gotta send a message back to the core other than with seatupdate so the core knows it came from here and updates slots list there.
						llMessageLinked(LINK_SET, (seatupdate + 2000000), llDumpList2String(slots, "^"), NULL_KEY);
					}

				return;
			}

		if(num == 204)
			{
				integer n;
				string primName = llGetObjectName();
				llSetObjectName(llGetLinkName(1));

				for(n = 0; n < llGetListLength(slots) / 8; ++n)
					{
						list slice = llList2List(slots, n * stride, n * stride + 3);
						slice = llListReplaceList(slice, [RAD_TO_DEG * llRot2Euler(llList2Rot(slice, 2))], 2, 2);
						string sendSTR = "ANIM|" + llDumpList2String(slice, "|");
						llRegionSayTo(llGetOwner(), 0, "\n" + sendSTR);
					}

				llRegionSay(chatchannel, "posdump");
				llSetObjectName(primName);

				return;
			}

		if(num == memusage)
			{
				llSay(0, "Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
				      + ",Leaving " + (string)llGetFreeMemory() + " memory free.");
			}
	}

	event run_time_permissions(integer perm)
	{
		DEBUGmsg0("runtime perms triggered");

		thisAV = llGetPermissionsKey();

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
							if(sits(thisAV))
								{
									llStartAnimation(currentanim);
								}
						}
				}
				else
					if(sits(thisAV))
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
			for(; seatcount < stop - 1;)
				{
					seatcount += 1;

					if(llList2Key(slots, seatcount * 8 + 4) != "")
						{
							doSeats(seatcount, llList2String(slots, (seatcount) * 8 + 4));
							return;
						}
				}
		}

	timer()
		{
			when(facialEnable != "on")
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
											llRequestPermissions(av, PERMISSION_TRIGGER_ANIMATION);
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
										llRequestPermissions(av, PERMISSION_TRIGGER_ANIMATION);
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
