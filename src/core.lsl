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


#define DEBUG0 0  // card reading
#define DEBUG1 0  // listener
#define DEBUG2 0  // process line
#define DEBUG3 0  // slotMax, assigning slots, sending slots

// #define DEBUG_tellmem  // memory info
// #define DEBUG_ShowSlots  // show slots and changes


#include <lslstddef.h>
#include <undetermined.h>
#include <avn/core.h>

#include <common-slots.h>

#include <core.h>
#include <constants.h>
#include <core-inline.h>
#include <sitting.h>


ProcessLine(string line, key av)
{
	line = llStringTrim(line, STRING_TRIM);
	list params = llParseString2List(line, ["|"], []);
	string action = llList2String(params, 0);

	// slots:  animationName, position vector, rotation vector, facial anim name, seated AV key, SATMSG, NOTSATMSG, Seat#
	// params: ANIM          | meditation     | <-0.3,0,0.8>    | <0,0,0>        | facial (optional)
	//           0              1               2              3        4

	if("ANIM" == action)
		{

			DEBUGmsg2("test vector:", ForceList2Vector(params, 2));
			// params[4] does not exist?
			// inconsistent: slots[4] is a UUID, not a string

			if(slotMax < lastStrideCount)
				{
					slots = llListReplaceList(slots, [llList2String(params, 1), ForceList2Vector(params, 2),
									  Vec2Rot(ForceList2Vector(params, 3)), llList2Key(params, 4), llList2Key(slots, (slotMax) * stride + 4),
									  "", "", "seat" + (string)(slotMax + 1)], slotMax * stride, slotMax * stride + 7);

					DEBUGmsg2("slots replace, params:", llList2CSV(params));
				}
			else
				{
					slots += [llList2String(params, 1), ForceList2Vector(params, 2),
						  Vec2Rot(ForceList2Vector(params, 3)), llList2String(params, 4), "", "", "", "seat" + (string)(slotMax + 1)];

					DEBUGmsg2("slots add, params    :", llList2CSV(params));
				}

			slotMax++;

			DEBUGmsg2("slotMax:", slotMax);

			DEBUG_TellMemory("ANIM");

			return;
		}

	if("SINGLE" == action)
		{
			//this pose is for a single sitter within the slots list
			//got to find out which slot and then replace the entire slot

			integer posIndex = LstIdx(slots, ForceList2Vector(params, 2));

			if((posIndex == -1) || ((posIndex != -1) && llList2String(slots, posIndex - 1) != llList2String(params, 1)))
				{
					integer slotindex = llListFindList(slots, [clicker]) - 4;
					slots = llListReplaceList(slots, [llList2String(params, 1), ForceList2Vector(params, 2),
									  Vec2Rot(ForceList2Vector(params, 3)), llList2String(params, 4),
									  llList2Key(slots,
										     slotindex + 4), "", "", llList2String(slots, slotindex + 7)], slotindex, slotindex + 7);


					// replacing up to slotindex + 7 means that at least ((slotindex + 7 +
					// stride - 7) / stride) slots must be considered
					//
					int newmax = (slotindex + 7 + stride - 7) / stride;
					when(newmax > slotMax)
						{
							ERRORmsg("slot gap:", newmax - slotMax, "slots");

							slotMax = newmax;
							lastStrideCount = slotMax;
						}
				}

#if 0
			// this was a replacement, no adjustment needed here?
			//
			slotMax = llGetListLength(slots) / stride;
			lastStrideCount = slotMax;
#endif

			DEBUG_TellMemory("SINGLE");

			return;
		}

	if("PROP" == action)
		{
			string obj = llList2String(params, 1);

			if(llGetInventoryType(obj) == INVENTORY_OBJECT)
				{
					list strParm2 = llParseString2List(llList2String(params, 2), ["="], []);

					if(llList2String(strParm2, 1) == "die")
						{
							llRegionSay(chatchannel, llList2String(strParm2, 0) + "=die");
						}
					else
						{
							bool expl = (llList2String(params, 4) == "explicit");
							CompStatus(stEXPLICIT, expl);

							vector vDelta = ForceList2Vector(params, 2);
							vector pos = llGetPos() + (vDelta * llGetRot());
							rotation rot = Vec2Rot(ForceList2Vector(params, 3)) * llGetRot();

							if(llVecMag(vDelta) > 9.9)
								{
									//too far to rez it direct.  need to do a prop move
									llRezAtRoot(obj, llGetPos(), ZERO_VECTOR, rot, chatchannel);
									llSleep(1.0);
									llRegionSay(chatchannel, llDumpList2String(["MOVEPROP", obj, (string)pos], "|"));
								}
							else
								{
									llRezAtRoot(obj, llGetPos() + (ForceList2Vector(params, 2) * llGetRot()), ZERO_VECTOR, rot, chatchannel);
								}
						}
				}

			DEBUG_TellMemory("PROP");

			return;
		}

	if("LINKMSG" == action)
		{
			integer num = llList2Integer(params, 1);
			string line1 = str_replace(line, "%AVKEY%", av);
			list params1 = llParseString2List(line1, ["|"], []);
			key lmid = llList2Key(params1, 3);

			when(lmid == "")
				{
					lmid = kSlots2Ava(slotMax - 1);
				}

			string str = llList2String(params1, 2);
			llMessageLinked(LINK_SET, num, str, lmid);

			// why sleep here?
			//
			llSleep(1.0);
			llRegionSay(chatchannel, llDumpList2String(["LINKMSGQUE", num, str, lmid], "|"));

			DEBUG_TellMemory("LINKMSG");

			return;
		}

	if("SATMSG" == action)
		{
			integer index = (slotMax - 1) * stride + 5;
			slots = llListReplaceList(slots, [llDumpList2String([llList2String(slots, index),
									     llDumpList2String(llDeleteSubList(params, 0, 0), "|")], "�")], index, index);
			DEBUG_TellMemory("SATMSG");

			return;
		}

	if("NOTSATMSG" == action)
		{
			integer index = (slotMax - 1) * stride + 6;
			slots = llListReplaceList(slots, [llDumpList2String([llList2String(slots, index),
									     llDumpList2String(llDeleteSubList(params, 0, 0), "|")], "�")], index, index);

			DEBUG_TellMemory("NOTSATMSG");
		}
}

default
{
	event state_entry()
	{
		afootell(concat(concat(llGetScriptName(), " "), VERSION));

		DEBUG_TellMemory("entry");


		int n = llGetObjectPrimCount(llGetKey());
		unless(n)
		{
			// this prim is not linked
			//
			llLinkSitTarget(n, <0.0, 0.0, 0.5>, ZERO_ROTATION);
		}
		while(n)
			{
				// this prim is linked
				//
				llLinkSitTarget(n, <0.0, 0.0, 0.5>, ZERO_ROTATION);
				--n;
			}


		chatchannel = (integer)("0x" + llGetSubString((string)llGetKey(), 0, 7));
		llMessageLinked(LINK_SET, 1, (string)chatchannel, NULL_KEY); //let our scripts know the chat channel for props and adjusters

		curPrimCount = llGetNumberOfPrims();
		lastPrimCount = curPrimCount;

		llListen(chatchannel, "", NULL_KEY, "");

		card = "";
		int stop = llGetInventoryNumber(INVENTORY_NOTECARD);

		DEBUGmsg0("notecards:", stop);
		DEBUG_TellMemory("entry 1");

		// n is already 0 from above
		//
		while(n < stop)
			{
				card = llGetInventoryName(INVENTORY_NOTECARD, n);

				// either be 0
				//
				unless(Stridx(card, defaultprefix) && Stridx(card, cardprefix))
					{
						llMessageLinked(LINK_SET, DOPOSE, card, NULL_KEY);
						DEBUGmsg0("card: '", card, "'");
						return;
					}
				++n;
			}

		DEBUGmsg0("no card found");
	}

	event link_message(integer sender, integer num, string str, key id)
	{
		DEBUG_TellMemory("linkmsg");

		if(num == SEND_CHATCHANNEL)  //slave has asked me to reset so it can get the chatchannel from me.
			{
				// randomly resetting may cause timing issues
				//
				// send chat channel instead and update slots
				//
				llMessageLinked(LINK_SET, 1, (string)chatchannel, NULL_KEY);
				virtualSendSlotUpdate(slots);
				ERRORmsg("reset denied");
			}

		if(num == DOPOSE)
			{
				DEBUGmsg0("--> Lmsg DOPOSE:", "sender:", sender, "num:", num, "str:", str, "id:", id);

				card = str;
				clicker = id;
				ReadCard();

				return;
			}

		if(num == DOACTIONS)
			{
				btncard = str;
				clicker = id;
				btnline = 0;
				btnid = llGetNotecardLine(btncard, btnline);

				return;
			}

		if(num == ADJUST)
			{
				SetStatus(stADJUSTERS);
				return;
			}

		if(num == STOPADJUST)
			{
				UnStatus(stADJUSTERS);
				return;
			}

		if(num == CORERELAY)
			{
				list msg = llParseString2List(str, ["|"], []);

				if(id != NULL_KEY)
					{
						msg = llListReplaceList(msg, [id], 2, 2);
					}

				llRegionSay(chatchannel, llDumpList2String(["LINKMSG"] + llList2List(msg, 0, 2), "|"));

				return;
			}

		if(num == SWAP)
			{
				DEBUGmsg3("should swap some of", slotMax, "slots");
				// length is irrelevant
				//
				// if(llGetListLength(slots) / stride >= 2)
				when(slotMax > 1)
					{
						DEBUGmsg3("swapping some of", slotMax, "slots");
						list seats2Swap = llParseString2List(str, [","], []);
						SwapTwoSlots(llList2Integer(seats2Swap, 0), llList2Integer(seats2Swap, 1));
					}

				return;
			}

		if(num == SWAPTO)
			{
				SwapAvatarInto(id, (int)str);

				return;
			}

		if(num == (seatupdate + 2000000))
			{
				//slave sent slots list after adjuster moved the AV.  we need to keep our slots list up to date. replace slots list

				list tempList = llParseStringKeepNulls(str, ["^"], []);
				integer listStop = llGetListLength(tempList) / stride;
				integer slotNum;

				for(slotNum = 0; slotNum < listStop; ++slotNum)
					{
						slots = llListReplaceList(slots, [llList2String(tempList, slotNum * stride), ForceList2Vector(tempList, slotNum * stride + 1),
										  ForceList2Rot(tempList, slotNum * stride + 2), llList2String(tempList, slotNum * stride + 3),
										  llList2Key(tempList, slotNum * stride + 4), llList2String(tempList, slotNum * stride + 5),
										  llList2String(tempList, slotNum * stride + 6), llList2String(tempList, slotNum * stride + 7)], slotNum * stride, slotNum * stride + 7);
					}

				return;
			}

		if(num == -999 && str == "RezHud")
			{
				if(llGetInventoryType(adminHudName) != INVENTORY_NONE)
					{
						llRezObject(adminHudName, llGetPos() + <0, 0, 1>, ZERO_VECTOR, llGetRot(), chatchannel);
					}

				return;
			}

		if(num == -999 && str == "RemoveHud")
			{
				llRegionSayTo(hudId, chatchannel, "/die");

				return;
			}

		if(num == memusage)
			{
				llSay(0, "Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.");

				return;
			}
	}

	event object_rez(key id)
	{
		if(llKey2Name(id) == adminHudName)
			{
				hudId = id;
				llSleep(2.0);
				llRegionSayTo(hudId, chatchannel, "parent|" + (string)llGetKey());
			}
	}

	event listen(integer channel, string name, key id, string message)
	{
		when(llGetOwner() != llGetOwnerKey(id))
			{
				return;
			}

		DEBUG_TellMemory("listener");

		unless(name != "Adjuster")
			{
				llMessageLinked(LINK_SET, 3, message, id);

				return;
			}

		unless(id != hudId)
			{
				//need to process hud commands

				list hudcommands = ["adjust", ADJUST, "stopadjust", STOPADJUST, "posdump", DUMP, "hudsync", SYNC];
				int $_ = LstIdx(hudcommands, message);
				if(~$_)
					{
						llMessageLinked(LINK_SET, llList2Integer(hudcommands, $_ + 1), "", "");
					}

				return;
			}

		bool $_0 = (llGetSubString(message, 0, 4) == "ping");
		bool $_1 = (llGetSubString(message, 0, 8) == "PROPRELAY");
		if($_0 || $_1)
			{
				if($_0)
					{
						llRegionSay(chatchannel, "pong|" + (string)HasStatus(stEXPLICIT) + "|" + (string)llGetPos());

						return;
					}

				if($_1)
					{
						list msg = llParseString2List(message, ["|"], []);
						llMessageLinked(LINK_SET, llList2Integer(msg, 1), llList2String(msg, 2), llList2Key(msg, 3));
					}

				return;
			}

		DEBUGmsg1("the message here is:", message);

		// supposedly a message from a prop, intended to do some rotation/positioning
		//
		list params = llParseString2List(message, ["|"], []);
		unless(Len(params) < 2)
			{
				vector newpos = ForceList2Vector(params, 0) - llGetPos();
				newpos /= llGetRot();
				rotation newrot = ForceList2Rot(params, 1) / llGetRot();

				string $_ = "\nPROP|" + name + "|" + (string)newpos + "|" + (string)(llRot2Euler(newrot) * RAD_TO_DEG) + "|" + llList2String(params, 2);
				llRegionSayTo(llGetOwner(), 0, $_);
				llMessageLinked(LINK_SET, slotupdate, $_, NULL_KEY);
			}
	}

	event dataserver(key id, string data)
	{
		if(id == dataid)
			{
				unless(EOF == data)
					{
						DEBUGmsg0("line", line, "of '", card, "' has been received");

						ProcessLine(data, clicker);
						line++;

						DEBUGmsg0("attempt to read card: '", card, "', line", line);

						dataid = llGetNotecardLine(card, line);

						DEBUG_TellMemory("DS data DTA");

						return;
					}


				DEBUGmsg0("dataserver: EOF");
				DEBUGmsg3("slotMax:", slotMax, "last stride count:", lastStrideCount);

				when(slotMax < lastStrideCount)
					{
						DEBUGmsg3("the number of slots has been reduced from", lastStrideCount, "to", slotMax);

						//
						// the number of slots has been reduced by reading another card
						//

						//AV's that were in a 'real' seat are already assigned so leave them be

						// agents cannot have a slot assigned when the slot has been removed

						// find an empty slot
						//
#ifdef _INLINE_FindEmptySlot
						int emptySlot;
						FindEmptySlot(emptySlot);
#else
						integer emptySlot = FindEmptySlot();
#endif

						int x = slotMax;
						while(x <= lastStrideCount) //only need to worry about the 'extra' slots so limit the count
							{
								//
								// go through all the slots that have been removed
								// They are virtual slots, not yet removed.
								//
								// When the virtual slot is assigned to an agent, find a free slot and
								// assign it to that agent, rather than unsitting the agent.
								//

								key agent = kSlots2Ava(x);

								if(agent)
									{
										unless(emptySlot < 0)
											{
												// no free slot is available, so unsit the agent from the slot
												//
												if(sits((key)agent))
													{
														llMessageLinked(LINK_SET, iUNSIT, agent, NULL_KEY);
														DEBUGmsg2("no slot for", llGetUsername(agent));
													}
											}
										else
											{
												//if AV in a 'now' extra seat and if a real seat available, seat them
												slots = llListReplaceList(slots, [llList2Key(slots, x * stride + 4)], emptySlot * stride + 4, emptySlot * stride + 4);

												// There may still be free slots: Find another free slot.
												//
#ifdef _INLINE_FindEmptySlot
												FindEmptySlot(emptySlot);
#else
												emptySlot = FindEmptySlot();
#endif
											}
									}

								++x;
							}

						//remove the 'now' extra seats from slots list
						// remove the virtual slots
						//
						slots = llDeleteSubList(slots, slotMax * stride, -1);
						lastStrideCount = slotMax;
					}

				DEBUG_virtualShowSlots(slots);

				// send slots list to other scripts
				//
				virtualSendSlotUpdate(slots);

				// card has been read and we have adjusters, send message to slave script.
				//
				IfStatus(stADJUSTERS)
					{
						llMessageLinked(LINK_SET, 2, "RezAdjuster", "");
					}

				DEBUG_TellMemory("DS data EOF");

				return;
			}

		if((id == btnid) && (data != EOF))
			{
				ProcessLine(data, clicker);
				btnline++;

				DEBUGmsg0("attempt to read btn card: '", btncard, "', line", btnline);

				btnid = llGetNotecardLine(btncard, btnline);

				DEBUG_TellMemory("DS data button");
			}
	}

	event changed(integer change)
	{
		if(change & CHANGED_LINK)
			{
				llMessageLinked(LINK_SET, 1, (string)chatchannel, NULL_KEY); //let our scripts know the chat channel for props and adjusters
				lastPrimCount = curPrimCount;
				curPrimCount = llGetNumberOfPrims();

				// assignSlots()

				// called after a SET card was read or when the linkset changed
				// no verification whether the link set changed because of a prim or an agent?

				// most recent sitter
				//
				key thisKey = llGetLinkKey(llGetNumberOfPrims());

				when((curPrimCount < lastPrimCount) || !boolIsAgent(thisKey))
					{
						// either no agents are sitting, or there are not as many agents sitting
						// as there were
						//
						// this is ok as well when the linkset changed because a prim was
						// (un-)linked


						// unassign slots from all agents in the slot list who aren�t sitting on a prim
						//
						int n = Len(slots) / stride;

						LoopDown(n,
							 if(!sits(kSlots2Ava(n)))
								 {
									 slots = llListReplaceList(slots, [""], n * stride + 4, n * stride + 4);
									 DEBUGmsg2("unassigned slot of agent:", kSlots2Ava(n));
								 }
							 );

						lastPrimCount = curPrimCount;

						// send slots list to other scripts
						//
						virtualSendSlotUpdate(slots);

						return;
					}

				if(curPrimCount > lastPrimCount)
					{
						//we have a new AV, if a seat is available then seat them
						//if not, unseat them
						//numbered seats take priority so check if new AV is on a numbered prim
						//find the new seated AV
						//step through the prims to see if our new AV has a numbered seat


						// assign a slot to the last sitting agent:
						//
						// When the agent is sitting on a prim the name of which can be cast to an integer,
						// and when the integer is valid as a slot number, then assign the slot that has
						// this number to the agent unless there is already a slot assigned to the agent.
						//
						if(NotOnlst(slots, thisKey))  // may fail when the UUID is as string on the list
							{
								integer primcount = llGetObjectPrimCount(llGetKey());
								int n = 1;
								while(n <= primcount) //find out which prim this new AV is seated on and grab the slot number if it's a numbered prim.
									{
										integer slotNum = (integer)llGetLinkName(n);
										DEBUGmsg2("slotNum:", slotNum);

										if((slotNum > 0) && (slotNum <= slotMax))
											{
												if(llAvatarOnLinkSitTarget(n) == thisKey)
													{
														if(kSlots2Ava(slotNum - 1) == "")  // this is supposed to be a UUID
															{
																slots = llListReplaceList(slots, [thisKey], (slotNum - 1) * stride + 4, (slotNum - 1) * stride + 4);
																DEBUGmsg2(llGetUsername(thisKey), "is put into slot", slotNum - 1);
															}
													}
											}
										++n;
									}

								DEBUG_virtualShowSlots(slots);
							}

						// When the sitting agent did not get a slot assigned, they are either
						// not sitting on a a prim the name of which can be cast to an integer,
						// or all such prims already have agents sitting on them.
						//
						// Find a free slot and assign it to the agent.  Unless a free slot can
						// be found, unsit the agent.
						//
						if(NotOnlst(slots, thisKey))  // may fail when the UUID is as string on the list
							{
#ifdef _INLINE_FindEmptySlot
								int freeslot;
								FindEmptySlot(freeslot);
#else
								integer freeslot = FindEmptySlot();
#endif

								if(freeslot >= 0)
									{
										//we have a spot.. seat them
										slots = llListReplaceList(slots, [thisKey], freeslot * stride + 4, freeslot * stride + 4);

										DEBUGmsg2(llGetUsername(thisKey), "has been entered into the slots list");
									}
								else
									{
										// don�t unsit agent when they aren�t sitting anymore
										//
										if(sits(thisKey))
											{
												//no open slots, so unseat them
												llMessageLinked(LINK_SET, iUNSIT, (string)thisKey, NULL_KEY);
												DEBUGmsg2("no slots to sit", llGetUsername(thisKey));
											}
									}

								DEBUG_virtualShowSlots(slots);

							}

						// send slots list to other scripts
						//
						virtualSendSlotUpdate(slots);

						DEBUG_TellMemory("assign slots");
					}

				// / assignSlots()
			}

		if(change & CHANGED_INVENTORY)
			{
				llResetScript();
			}

#if 0
		if(change & CHANGED_REGION)
			{
				// Why send a seatupdate on region changes?
				//
				virtualSendSlotUpdate(slots);
			}
#endif

	}

	event on_rez(integer param)
		{
			llResetScript();
		}
}
