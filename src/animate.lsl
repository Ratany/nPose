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
#define DEBUG2 1  // mkanimslist()
#define DEBUG3 1  // repeated anims

// #define _STD_DEBUG_PUBLIC


#include <lslstddef.h>
#include <undetermined.h>
#include <avn/animate.h>

#include <common-slots.h>
#include <constants.h>


int status = 0;
#define stSLOTS_RCV                1
#define stON_TIMER                 2
#define stNO_RECURSE               8
#define stIGNORE_RT_PERMS         16
#define stDOSYNC                  32
#define stFACE_DISABLE            64


#define flagPERMS                  PERMISSION_TRIGGER_ANIMATION


// #define DEBUG_Showanimslist
#include <animslist.h>


#define fTIMER                     1.0

#define xTimerOff                  llSetTimerEvent(0.0); UnStatus(stON_TIMER)
#define xTimerOn                   llSetTimerEvent(fTIMER); SetStatus(stON_TIMER)


// the last seat that was animated
// needed to figure out which agent to animate next
//
int iLastAnimatedSeat;

key kMYKEY;


list slots;


// list of animations not to stop
//
// These anims are not stopped when anims are stopped, and they are
// started.  Repeatable anims are repeated.
//
// see animslist.h
//
// [agent uuid, anim name, repeat counter]
//
list lUnstoppable;


//we need a list consisting of sitter key followed by each face anim and the associated time of each
// put face anims for each slot into a list
//
// for now, rebuild the list for all slots :/
//
void mkanimlist()
{
	//
	// put potentially repeatable animations on the list of unstoppable anims
	//
	// done with every slot update
	//

	// before putting more anims on the list, remove obsolete entries
	//
	int $_ = Len(lUnstoppable) / iSTRIDE_lUnstoppable;
	LoopDown($_,
		 bool obsolete = FALSE;

		 // an entry is obsolete when it´s for an agent not on the slots list
		 //
		 int agentslot = LstIdx(slots, kUnstoppableToAgent(lUnstoppable, $_));
		 when(iIsUndetermined(agentslot))
		 {
			 obsolete = TRUE;
		 }
		 else
			 {
				 // an entry is obsolete when the agent is in a different slot
				 //
				 when(iSlots2SeatNo(agentslot) != iUnstoppableToSeatNo(lUnstoppable, $_))
					 {
						 obsolete = TRUE;
					 }
				 else
					 {
						 // an entry is obsolete when repeatable anims are disabled and it is to be repeated,
						 // or when the repeat counter is 0
						 //
						 int repeat = iUnstoppableToRepeat(lUnstoppable, $_);
						 if(!repeat || (HasStatus(stFACE_DISABLE) && (iREPEAT_INDEFINITELY == repeat)))
							 {
								 obsolete = TRUE;
							 }
					 }
			 }

		 // remove the entry when it´s obsolete
		 //
		 when(obsolete)
			 {
				 yUnstoppableRM(lUnstoppable, $_);
			 }
		 );


	// when repeatable anims are disabled, don´t enlist them at all
	//
	IfStatus(stFACE_DISABLE)
	{
		DEBUGmsg2("repeatables not enabled");
		return;
	}


	// when repeatable anims are enabled, put them onto the list
	//
	$_ = Len(slots) / stride;
	LoopDown($_,
		 key agent = kSlots2Ava($_);
		 if(agent)
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
							  DEBUGmsg2("len temp:", Len(temp));
							  //time must be optional so we will make default a zero
							  //queue on zero to revert to older stuff
							  when(Len(temp) > 1)
							  {
								  if(llList2String(temp, 1))
									  {
										  // put anim and repeat counter on list for this agent
										  // the animation is repeated until the counter is 0
										  // --- the minimum is 1
										  //
										  int repeat = llList2Integer(temp, 1);
										  repeat = Max(1, repeat);
										  xUnstoppableAdd(lUnstoppable, agent, llList2String(temp, 0), repeat, kSlots2SeatNo($_));  // uses Enlist()
									  }
							  }
							  else
								  {
									  when(Len(temp))
										  {
											  if(llList2String(temp, 0))
												  {
													  // put anim on list for this agent
													  // and mark as to be repeated indefinitely
													  //
													  xUnstoppableAdd(lUnstoppable, agent, llList2String(temp, 0), iREPEAT_INDEFINITELY, kSlots2SeatNo($_));  // uses Enlist()
												  }
										  }
								  }
							  );
					 }
			 }
		 );

	DEBUGmsg2("list rebuilt");
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

						// reset the slots list
						//
						slots = [];

						// reset ...
						//
						lUnstoppable = [];

						// stop the timer for the while so it doesn´t mess with anything
						//
						xTimerOff;

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

						// reset and rebuild
						//
						mkanimlist();

						// reset this because a new cycle starts
						//
						iLastAnimatedSeat = iUNDETERMINED;
						UnStatus(stNO_RECURSE);

						// Once alls slots have been received
						// and the face anims list has been created, ask someone for perms to
						// initiate playing animations.
						//
						// requesting perms from a prim yields a script error ...
						//
						key agent = llGetLinkKey(llGetNumberOfPrims());
						when(AgentIsHere(agent))  // no point in animating when nobody is here ...
							{
								int $_ = LstIdx(slots, agent);
								unless(iIsUndetermined($_))  // ... or when the last sitter doesn´t have a slot
									{
										DEBUGmsg1("perm req after full slot update");
										llRequestPermissions(agent, flagPERMS);
										return;
									}
							}
						//
						// Note: When the last sitter doesn´t have a slot, the core will unsit
						// them and send a slot update.  Unfortunately, this doesn´t mean that
						// anyone will be animated.  Hence:
						//
						int $_ = Len(slots) / stride;
						LoopDown($_, agent = kSlots2Ava($_); if(agent) { llRequestPermissions(agent, flagPERMS); return; });
						//
						// ... and if there really is nobody there, there do nothing:
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

					// update the list of unstoppable anims with every slot received
					//
					when(kSlots2Ava(Len(slots) / stride - 1))
						{
							// enlist the animation from the slot --- plays indefinitely
							// mark as not started yet
							//
							xUnstoppableAdd(lUnstoppable, kSlots2Ava(Len(slots) / stride - 1), sSlots2Pose(Len(slots) / stride - 1), iNOT_STARTED_YET, kSlots2SeatNo(Len(slots) / stride - 1));
						}

					return;
				}

				ERRORmsg("protocol violation");
				return;
			}  // seatupdate


		virtualReceiveSlotSingle(str, slots, num, id, kMYKEY,
					 DEBUGmsg0("single slot received");

					 // reset and rebuild the list
					 //
					 mkanimlist();

					 // if the updated slot has an agent assigned, add the animation from
					 // the slot to the list of unstoppable anims for this agent; then ask
					 // for perms to animate the agent
					 //
					 when(kSlots2Ava($_slotnum))
					 {
						 DEBUGmsg1("perm req after single slot update");
						 // enlist the animation from the slot --- plays indefinitely
						 // mark as not started yet
						 //
						 xUnstoppableAdd(lUnstoppable, kSlots2Ava($_slotnum), sSlots2Pose($_slotnum), iNOT_STARTED_YET, kSlots2SeatNo($_slotnum));

						 SetStatus(stNO_RECURSE);
						 llRequestPermissions(kSlots2Ava($_slotnum), flagPERMS);
					 }
					 );


		if(num == layerPose)
			{
				// Starting and stopping animations can only be done when permissions
				// have been granted.
				//

				DEBUGmsg0("layer pose message rcvd:", str);

				key av = llList2Key(llParseString2List(str, ["/"], []), 0);
				if(av)
					{
						// figure out what to do
						//
						list tempList1 = llParseString2List(llList2String(llParseString2List(str, ["/"], []), 1), ["~"], []);

						integer layerStop = llGetListLength(tempList1);
						integer n;  // instruction
						for(n = 0; n < layerStop; ++n)
							{
								list tempList = llParseString2List(llList2String(tempList1, n), [","], []);

#define tmpCMD                     llList2String(tempList, 0)
#define tmpANIM                    llList2String(tempList, 1)

								string cmd = tmpCMD;

								if(cmd == "stopAll")
									{
										// Remove all anims for this agent from the list of
										// unstoppable animations.  They will be stopped in
										// the perms event.
										//
										DEBUGmsg1("stop all anims");

										int weed = Len(lUnstoppable) / iSTRIDE_lUnstoppable;
										LoopDown(weed,
											 when(kUnstoppableToAgent(lUnstoppable, weed) == av)
											 {
												 yUnstoppableRM(lUnstoppable, weed);
											 }
											 );
									}
								else
									{
										when(cmd == "stop")
											{
												// Remove a particular anim for this agent
												// from the list of unstoppable anims.
												// It will be stopped in the perms event.
												//
												DEBUGmsg1("stop single anim:", tmpANIM);

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
														// Add a particular anim for this agent
														// to the list of unstoppable anims.
														// It will be started in the perms event.
														//
														DEBUGmsg1("start single anim:", tmpANIM);
														int $_ = LstIdx(slots, av);
														unless(iIsUndetermined($_))
															{
																$_ /= stride;
																xUnstoppableAdd(lUnstoppable, av, tmpANIM, iNOT_STARTED_YET, kSlots2SeatNo($_));
															}
													}
												else
													{
														ERRORmsg("unknown cmd");
													}
											}
									}
							}  // for()
#undef tmpCMD
#undef tmpANIM

						// Processing the animation change(s) has completed.  Now trigger the
						// perms event to apply the changes.
						//
						DEBUGmsg1("request perms to apply animation changes");
						SetStatus(stNO_RECURSE);
						llRequestPermissions(av, flagPERMS);
					}
				return;
			}  // num == LayerPose

		if(num == SYNC)
			{
				ERRORmsg("method not yet implemented");
#if 0
				SetStatus(stDOSYNC);
				integer $_ = llGetListLength(slots) / 8;
				LoopDown($_, key agent = kSlots2Ava($_); if(agent) { DEBUGmsg1("perm req sync"); llRequestPermissions(agent, flagPERMS); });

				// after syncing is completed, unset the status
				//
				// Executing more code when explicitly syncing seems to be the only
				// purpose for this status.
				//
				UnStatus(stDOSYNC);
#endif

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

				// this requires a rebuild
				//
				mkanimlist();
				//
				// and a reset
				//
				iLastAnimatedSeat = iUNDETERMINED;
				//
				// and a timer start
				//
				IfNStatus(stON_TIMER)
				{
					xTimerOn;
				}
				//
				// yeah it sucks ...
				// /

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

		DEBUGmsg("runtime perms triggered");

		// Stop all anims in inventory that aren´t in the slot
		// and stoppable, and start the unstoppable ones.
		//
		inlineAnimsStopAll(agent, lUnstoppable);

		IfNStatus(stNO_RECURSE)
		{
			// don´t need the timer while the agents are animated from here
			//
			xTimerOff;

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
									 // check if there are anims to start
									 //
									 int u = Len(lUnstoppable) / iSTRIDE_lUnstoppable;
									 LoopDown(u,
										  int repeat = iUnstoppableToRepeat(lUnstoppable, u);

										  // Note: (iHAS_BEEN_STARTED != repeat) leaves iREPEAT_INDEFINITELY and iNOT_STARTED_YET
										  // Should more possibilities be added, this expression needs to be changed.
										  //
										  when(((iHAS_BEEN_STARTED != repeat) || (0 < repeat)) && (kUnstoppableToAgent(lUnstoppable, u) == nextagent))
										  {
											  iLastAnimatedSeat = iSlots2SeatNo($_);
											  DEBUGmsg1("perm req next seat for", nextagent);
											  llRequestPermissions(nextagent, flagPERMS);
											  return;
										  }
										  );
								 }
						 }
				 }
				 );
		}

		// When all seats are through, flip the timer on to see if there are
		// repeating anims to play.
		//
		DEBUGmsg1("perm req returns");
		iLastAnimatedSeat = iUNDETERMINED;

		IfNStatus(stON_TIMER)
		{
			xTimerOn;
		}
	}

	event timer()
	{
		DEBUGmsg1("timer here");

		unless(llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) == ZERO_VECTOR)
			{
				int $_ = Len(lUnstoppable) / iSTRIDE_lUnstoppable;
				LoopDown($_,
					 int repeat = iUnstoppableToRepeat(lUnstoppable, _$);
					 unless(repeat)
					 {
						 yUnstoppableRM(lUnstoppable, $_);
					 }
					 else
						 {
							 when(((repeat == iREPEAT_INDEFINITELY) || (repeat > 0)) && (iLastAnimatedSeat < iUnstoppableToSeatNo(lUnstoppable, $_)))
								 {
									 DEBUGmsg1("perm req timer");
									 iLastAnimatedSeat = iUnstoppableToSeatNo(lUnstoppable, $_);
									 llRequestPermissions(kUnstoppableToAgent(lUnstoppable, $_), flagPERMS);

									 // can´t just "queue up" the requests here, so flop
									 // back to the perm event
									 //
									 // In case the event is never triggered, nothing happens
									 // and the timer stays on to query the next agent.
									 //
									 return;
								 }
						 }
					 );
			}

		// nobody needs to be animated
		//
		xTimerOff;
		DEBUGmsg1("timer self-off");
	}
}
