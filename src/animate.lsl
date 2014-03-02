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
#define DEBUG1 0  // animations
#define DEBUG2 0  // mkanimslist()
#define DEBUG3 0  // repetitions

// #define _STD_DEBUG_PUBLIC


#include <lslstddef.h>
#include <undetermined.h>
#include <avn/animate.h>

#include <common-slots.h>
#include <constants.h>

#define OUTLINE_sits
#include <sitting.h>

int status = 0;
#define stSLOTS_RCV                1
#define stON_TIMER                 2
#define stNO_RECURSE               4
#define stFACE_DISABLE             8


#define flagPERMS                  PERMISSION_TRIGGER_ANIMATION


// #define DEBUG_Showanimslist
#include <animslist.h>


#define fTIMER                     1.5

#define xTimerOff                  llSetTimerEvent(0.0); UnStatus(stON_TIMER)
#define xTimerOn                   iLastUnstoppableDone = -iSTRIDE_lUnstoppable; iPermsCounter = 0; llSetTimerEvent(fTIMER); SetStatus(stON_TIMER)


// the last slot that was animated
// needed to figure out which agent to animate next
//
// The order can be glitchy and may need to be established
// differently.  Testing is needed.
//
int iLastAnimatedSlot = -stride;
//
// same for lUnstoppable; initialized each time the timer is started
//
int iLastUnstoppableDone;
// /


// event counter, increased in perms event and checked in timer
//
// This is required to throttle down the permission requests to
// amounts that can be handled.  Without throttling, the event queue
// may run over and the script would become unresponsive.
//
// The throttle adjusts dynamically to the load.
//
int iPermsCounter = 0;


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

		 // an entry is obsolete when it´s for an agent not on the slots list
		 //
		 int agentslot = LstIdx(slots, kUnstoppableToAgent(lUnstoppable, $_));
		 when(iIsUndetermined(agentslot))
		 {
			 yUnstoppableRM(lUnstoppable, $_);
		 }
		 else
			 {
				 // an entry is obsolete when the agent is in a different slot
				 //
				 when(iSlots2SeatNo(agentslot) != iUnstoppableToSeatNo(lUnstoppable, $_))
					 {
						 yUnstoppableRM(lUnstoppable, $_);
					 }
				 else
					 {
						 // an entry is obsolete when repeatable anims are disabled and it is to be repeated,
						 // or when the repeat counter is 0
						 //
						 int repeat = iUnstoppableToRepeat(lUnstoppable, $_);
						 if(!repeat || (HasStatus(stFACE_DISABLE) && (iREPEAT_INDEFINITELY == repeat)))
							 {
								 yUnstoppableRM(lUnstoppable, $_);
							 }
					 }
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
										  xUnstoppableAdd(lUnstoppable, agent, llList2String(temp, 0), repeat, iSlots2SeatNo($_));  // uses Enlist()
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
													  xUnstoppableAdd(lUnstoppable, agent, llList2String(temp, 0), iREPEAT_INDEFINITELY, iSlots2SeatNo($_));  // uses Enlist()
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

		lUnstoppable = [];
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
						iLastAnimatedSlot = -stride;
						UnStatus(stNO_RECURSE);

						// Once alls slots have been received
						// and the face anims list has been created, ask someone for perms to
						// initiate playing animations.
						//
						// requesting perms from a prim yields a script error ...
						//
						int $_ = Len(slots) / stride;
						LoopDown($_, key agent = kSlots2Ava($_); if(agent) { if(sits(agent)) { llRequestPermissions(agent, flagPERMS); return; } });

						// if there is nobody here, then do nothing
						//
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
					int slotno = Len(slots) / stride - 1;
					when(kSlots2Ava(slotno))
						{
							// enlist the animation from the slot --- plays indefinitely
							// mark as not started yet
							//
							xUnstoppableAdd(lUnstoppable, kSlots2Ava(slotno), sSlots2Pose(slotno), iNOT_STARTED_YET, iSlots2SeatNo(slotno));
						}

					return;
				}

				ERRORmsg("protocol violation");
				return;
			}  // seatupdate


		virtualReceiveSlotSingle(str, slots, num, id, kMYKEY,
					 DEBUGmsg0("single slot received");
					 DEBUGmsg1("single slot received");

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
						 DEBUGmsg1("added", sSlots2Pose($_slotnum), "for", llGetUsername(kSlots2Ava($_slotnum)));
						 xUnstoppableAdd(lUnstoppable, kSlots2Ava($_slotnum), sSlots2Pose($_slotnum), iNOT_STARTED_YET, iSlots2SeatNo($_slotnum));

						 if(sits(kSlots2Ava($_slotnum)))
							 {
								 SetStatus(stNO_RECURSE);
								 DEBUGmsg1("perm req single slot update for", llGetUsername(kSlots2Ava($_slotnum)));
								 llRequestPermissions(kSlots2Ava($_slotnum), flagPERMS);
							 }
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
																xUnstoppableAdd(lUnstoppable, av, tmpANIM, iNOT_STARTED_YET, iSlots2SeatNo($_));
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
						if(sits(av))
							{
								DEBUGmsg1("request perms to apply animation changes");

								SetStatus(stNO_RECURSE);
								llRequestPermissions(av, flagPERMS);
							}
					}
				return;
			}  // num == LayerPose

		if(num == SYNC)
			{
				//
				// sync is supposed to restart all animations to get them in sync
				//

				// stop the timer
				xTimerOff;

				// stop the animations for all agents
				//
				int $_ = Len(lUnstoppable) / iSTRIDE_lUnstoppable;
				LoopDown($_, key agent = kUnstoppableToAgent(lUnstoppable, $_); inlineAnimsStopAll(agent));

				// set all non-repeating animations that have been started to not yet started
				//
				$_ = Len(lUnstoppable) / iSTRIDE_lUnstoppable;
				LoopDown($_, if(iHAS_BEEN_STARTED == iUnstoppableToRepeat(lUnstoppable, $_)) { yUnstoppableChgRepeat(lUnstoppable, $_, iNOT_STARTED_YET); });

				// rebuild the list of repeating anims to get those restarted, too
				//
				mkanimlist();

				// restart the animations
				//
				if(Len(lUnstoppable))
					{
						iLastAnimatedSlot = -stride;

						if(sits(kUnstoppableToAgent(lUnstoppable, 0)))
							{
								DEBUGmsg1("request perms to sync");

								// a slotupdate shall come when they don´t sit anymore
								//
								llRequestPermissions(kUnstoppableToAgent(lUnstoppable, 0), flagPERMS);
							}
					}

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
				iLastAnimatedSlot = -stride;
				//
				// and a restart
				//
				if(Len(lUnstoppable))
					{
						if(sits(kUnstoppableToAgent(lUnstoppable, 0)))
							{
								DEBUGmsg1("request perms to sync");

								// a slotupdate shall come when they don´t sit anymore
								//
								llRequestPermissions(kUnstoppableToAgent(lUnstoppable, 0), flagPERMS);
							}
					}
				//
				// yeah it sucks ...
				// /

				return;
			}
	}  // linked message

	event run_time_permissions(integer perm)
	{
		++iPermsCounter;

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

		DEBUGmsg3("runtime perms triggered");

		// Stop all anims in inventory that aren´t in the slot
		// and stoppable, and start the unstoppable ones.
		//
		inlineAnimate(agent, lUnstoppable);

		IfNStatus(stNO_RECURSE)
		{
			// find the next seat to do animations for and recurse
			//

			int stop = Len(slots) / stride;
			int $_ = (iLastAnimatedSlot += stride);
			while($_ < stop)
				{
					key nextagent = kSlots2Ava($_);
					when(nextagent)  // NULL_KEY || ""
					{
						when(nextagent != agent)
							{
								when(sits(nextagent))
									{
										// check if there are anims to start
										//
										int u = LstIdx(lUnstoppable, nextagent);
										unless(iIsUndetermined(u))
											{
												u /= iSTRIDE_lUnstoppable;

												int repeat = iUnstoppableToRepeat(lUnstoppable, u);

												// Note: (iHAS_BEEN_STARTED != repeat) leaves iREPEAT_INDEFINITELY and iNOT_STARTED_YET
												// Should more possibilities be added, this expression needs to be changed.
												//
												when(((iHAS_BEEN_STARTED != repeat) || (0 < repeat)))
													{
														iLastAnimatedSlot = $_;
														DEBUGmsg1("perm req next seat for", llGetUsername(nextagent));
														llRequestPermissions(nextagent, flagPERMS);
														return;
													}
											}
									}
							}
					}

					++$_;
				}
		}

		// When all seats are through, flip the timer on to see if there are
		// repeating anims to play.  When there aren´t any, there isn´t anything
		// to do until slots are updated.
		//
		DEBUGmsg1("perm req returns");
		iLastAnimatedSlot = -stride;
		UnStatus(stNO_RECURSE);

		IfNStatus(stON_TIMER)
		{
			xTimerOn;
		}
	}

	event timer()
	{
		DEBUGmsg3("timer here");

		unless(ZERO_VECTOR != llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())))
			{
				// nobody needs to be animated
				//
				xTimerOff;
				return;
			}


		// automatically throttle this down --- fTIMER should be at least 1.0
		//
		// Without the throttle, the event queue may run over and the script
		// becomes unresponsive to all events.
		//
		when(iPermsCounter > 1)
			{
				llSetTimerEvent(fTIMER * (float)iPermsCounter);
			}
		iPermsCounter = 0;


		unless(llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) == ZERO_VECTOR)
			{
				int stop = Len(lUnstoppable) / iSTRIDE_lUnstoppable;
				int $_ = (iLastUnstoppableDone += iSTRIDE_lUnstoppable);
				while($_ < stop)
					{
						int repeat = iUnstoppableToRepeat(lUnstoppable, _$);
						when(!repeat || !sits(kUnstoppableToAgent(lUnstoppable, $_)))
							{
								yUnstoppableRM(lUnstoppable, $_);
							}
						else
							{
								when((repeat == iREPEAT_INDEFINITELY) || (repeat > 0))
									{
										DEBUGmsg1("perm req timer");

										UnStatus(stNO_RECURSE);
										iLastUnstoppableDone = $_;
										llRequestPermissions(kUnstoppableToAgent(lUnstoppable, $_), flagPERMS);

										// can´t just "queue up" the requests here, so flop
										// back to the perm event
										//
										// In case the event is never triggered, the timer stays on to query the next agent.
										//
										return;
									}
							}

						++$_;
					}
			}

		// recurse after the set has been completed
		//
		iLastUnstoppableDone = -iSTRIDE_lUnstoppable;
	}
}
