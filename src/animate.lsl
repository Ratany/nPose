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


// animate.lsl: Handle animating agents.
//
// slave.lsl used to do this, but it´s busy with positioning and
// rotating the agents.


#define DEBUG0 0  // slotupdates
#define DEBUG1 1  // animations
#define DEBUG2 0  // mkanimslist()
#define DEBUG3 0  // stuff in the timer


#include <lslstddef.h>
#include <undetermined.h>
#include <avn/animate.h>

#include <common-slots.h>
#include <constants.h>


int status = 0;
#define stSLOTS_RCV                1
#define stFACE_ANIM_GOT            2
#define stNO_RECURSE               8
#define stIGNORE_RT_PERMS         16
#define stDOSYNC                  32
#define stFACE_DISABLE            64


#define flagPERMS                  PERMISSION_TRIGGER_ANIMATION


// #define DEBUG_Showanimslist
#include <animslist.h>


// the last seat that was animated
// needed to figure out which agent to animate next
//
int iLastAnimatedSeat;

key kMYKEY;


list slots;
list faceTimes;

// list of animations not to stop
//
list lUnstoppable;


//we need a list consisting of sitter key followed by each face anim and the associated time of each
// put face anims for each slot into a list
//
// rebuild the list for all slots :/
//
void mkanimlist()
{
	int $_ = Len(slots) / stride;
	LoopDown($_,
		 if(kSlots2Ava($_))
			 {
				 if(sSlots2Facials($_))
					 {
						 list faceanimsTemp = llParseString2List(sSlots2Facials($_), ["~"], []);
						 DEBUGmsg2("face anims temp:", llList2CSV(faceanimsTemp));
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
									  xUnstoppableAdd(lUnstoppable, kSlots2Ava($_), llList2String(temp, 0));
									  hasNewFaceTime = 1;
								  }
							  else
								  {
									  faces += ([llList2String(temp, 0), -1]);
								  }
							  );

						 SetStatus(stFACE_ANIM_GOT);

						 //add sitter key and flag if timer defined followed by a stride 2 list containing face anim name and associated time
						 DEBUGmsg2("adding to faceTimes:", llList2CSV([kSlots2Ava($_), hasNewFaceTime, Len(faceanimsTemp)] + faces));
						 faceTimes += ([kSlots2Ava($_), hasNewFaceTime, Len(faceanimsTemp)] + faces);
					 }
			 }
		 );
}




default
{
	event state_entry()
	{
		afootell(concat(concat(llGetScriptName(), " "), VERSION));

		iLastAnimatedSeat = iUNDETERMINED;
		lUnstoppable = faceTimes = [];
		kMYKEY = llGenerateKey();
	}

	event link_message(const int sender, const int num, const string str, const key id)
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

						slots = lUnstoppable = [];
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

						UnStatus(stFACE_ANIM_GOT);
						faceTimes = [];

						mkanimlist();

						// reset this because a new cycle starts
						//
						iLastAnimatedSeat = iUNDETERMINED;
						UnStatus(stNO_RECURSE);
						// /

						// Once alls slots have been received
						// and the face anims list has been created, ask someone for perms to
						// initiate playing the facials.
						//
						// requesting perms from a prim yields a script error
						//
						key agent = llGetLinkKey(llGetNumberOfPrims());
						when(AgentIsHere(agent))
							{
								int $_ = LstIdx(slots, agent);
								unless(iIsUndetermined($_))
									{
										iLastAnimatedSeat = iSlots2SeatNo($_);
										DEBUGmsg1("perm req after full slot update");
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

					return;
				}

				ERRORmsg("protocol violation");
				return;
			}  // seatupdate


		// ADD: GIVE PARAM TO MKANIMLIST() TO REBUILD A SINGLE SLOT ...
		//
		virtualReceiveSlotSingle(str, slots, num, id, kMYKEY,
					 DEBUGmsg0("single slot received");
					 mkanimlist();
					 int $_ = Len(lUnstoppable) / iSTRIDE_lUnstoppable;
					 LoopDown($_,
						  if(NotOnlst(slots, kUnstoppableToAgent(lUnstoppable, $_)))
							  {
								  yUnstoppableRM(lUnstoppable, $_);
							  }
						  );
					 when(kSlots2Ava(Len(slots) / stride - 1))
					 {
						 DEBUGmsg1("perm req after single slot update");
						 llRequestPermissions(kSlots2Ava(Len(slots) / stride - 1), flagPERMS);
					 }
					 );


		if(num == layerPose)
			{
				DEBUGmsg0("layer pose message rcvd:", str);

				key av = llList2Key(llParseString2List(str, ["/"], []), 0);

				DEBUGmsg1("perm req layer pose");
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
								int weed = Len(lUnstoppable) / iSTRIDE_lUnstoppable;
								LoopDown(weed,
									 when(kUnstoppableToAgent(lUnstoppable, weed) == av)
									 {
										 yUnstoppableRM(lUnstoppable, weed);
									 }
									 );

								// see animslist.h
								//
								inlineAnimsStopAll(av, lUnstoppable, ;);
								return;
							}

						when(cmd == "stop")
							{
								DEBUGmsg1("stop single anim:", tmpANIM);

								llStopAnimation(tmpANIM);
								int $_ = LstIdx(lUnstoppable, tmpANIM);
								unless(iIsUndetermined($_))
									{
										$_ /= iSTRIDE_lUnstoppable;
										yUnstoppableRM(lUnstoppable, $_);
									}
							}
						else
							{
								when(cmd == "start")
									{
										DEBUGmsg1("start single anim:", tmpANIM);
										llStartAnimation(tmpANIM);
										xUnstoppableAdd(lUnstoppable, av, tmpANIM);
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

		if(num == SYNC)
			{
				SetStatus(stDOSYNC);
				integer $_ = llGetListLength(slots) / 8;
				LoopDown($_, key agent = kSlots2Ava($_); if(agent) { DEBUGmsg1("perm req sync"); llRequestPermissions(agent, flagPERMS); });

				// after syncing is completed, unset the status
				//
				// Executing more code when explicitly syncing seems to be the only
				// purpose for this status.
				//
				UnStatus(stDOSYNC);

				return;
			}

		if(num == memusage)
			{
				MemTell;
			}

		if(iTOGGLE_FACIALS == num)
			{
				bool on = (str == "on");
				CompStatus(stFACE_DISABLE, !on);

				return;
			}
	}  // linked message

	event run_time_permissions(integer perm)
	{
		key agent = llGetPermissionsKey();

		unless((perm & flagPERMS))
			{
				// message to self
				//
				// core will update slots list on unsit
				//
				// This is probably not sane due to design.
				//
				llMessageLinked(LINK_THIS, iUNSIT, (string)agent, NULL_KEY);
				return;
			}

		IfStatus(stIGNORE_RT_PERMS)
		{
			return;
		}

		DEBUGmsg("runtime perms triggered");

		// Stop all anims in inventory that aren´t in the slot
		// and stoppable, and start the animation in the slot.
		//
		inlineAnimsStopAll(agent, lUnstoppable, llStartAnimation(sSlots2Pose(slot)); xUnstoppableAdd(lUnstoppable, agent, sSlots2Pose(slot)); DEBUGmsg1("started animation", sSlots2Pose(slot)));

		//start timer if we have face anims for any slot
		//
		IfStatus(stFACE_ANIM_GOT)
		{
			llSetTimerEvent(1.0);
		}
		else
			{
				llSetTimerEvent(0.0);
			}


		IfNStatus(stNO_RECURSE)
		{
			// find the next seat to do animations for and recurse
			//
			int $_ = Len(slots) / stride;
			LoopDown($_,
				 key nextagent = kSlots2Ava($_);
				 when(nextagent)  // NULL_KEY || ""
				 {
					 when(nextagent != agent)
						 {
							 when(iLastAnimatedSeat < iSlots2SeatNo($_))
								 {
									 //
									 // ADD CHECK IF THERE ARE ANIMS TO PLAY
									 //

									 iLastAnimatedSeat = iSlots2SeatNo($_);
									 DEBUGmsg1("perm req next seat for", nextagent);
									 llRequestPermissions(nextagent, flagPERMS);
									 return;
								 }
						 }
				 }
				 );
		}

		// Either all seats are through, so start over, or the timer has
		// messed with the order and which seat was animated last is
		// undetermined.
		//
		DEBUGmsg1("perm req returns");
		iLastAnimatedSeat = iUNDETERMINED;
	}

	event timer()
		{
			IfStatus(stFACE_DISABLE)
			{
				llSetTimerEvent(0.0);
				DEBUGmsg3("faces not enabled");
				return;
			}

			// set this to prevent recursion in the perms event
			//
			// The timer is going through all agents anyway.
			//
			SetStatus(stNO_RECURSE);

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
							list faceanims;
							//need to know if someone seated in this seat, if not we won't do any facials
							if(av != "")
								{
									faceanims = llParseString2List(llList2String(slots, n * 8 + 3), ["~"], []);
									facecount = llGetListLength(faceanims);

#if 0
									if(facecount && sits(thisAV))  //modified cause face anims were being imposed after AV stands.
										{
											thisAV = llGetPermissionsKey();
											llRequestPermissions(av, flagPERMS);
										}
#endif
								}

							integer x;

							for(x = 0; x < facecount; ++x)
								{
									if(facecount > 0)
										{
											if(faceindex < facecount)
												{
													llStartAnimation(llList2String(faceanims, faceindex));
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

#if 0
								//if we have facial anims make sure we have permissions for this av
								if((facecount > 0) && sits(thisAV))    //modified cause face anims were being imposed after AV stands.
									{
										thisAV = llGetPermissionsKey();
										llRequestPermissions(av, flagPERMS);
									}
#endif

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
														if(llList2Integer(faceTimes, faceStride + 1) > 0)
															{
																llStartAnimation(animName);
															}
														else
															if(llList2Integer(faceTimes, faceStride + 1) == -1)
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
				}

			UnStatus(stNO_RECURSE);
		}
}
