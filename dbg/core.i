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
// =repo-npose/core.i
integer status;
integer btnline;
integer chatchannel;
integer curPrimCount = 0;
integer lastPrimCount = 0;
integer lastStrideCount;
integer line;
integer slotMax = 0;
key btnid;
key clicker;
key dataid;
key hudId;
string btncard;
string card;
list slots;
integer sits(key k)
{
	integer b;
	{
		integer $_ = llGetNumberOfPrims();
		b = $_;

		while($_ && !(b = !(llGetLinkKey($_) != (k))) && (ZERO_VECTOR != llGetAgentSize(llGetLinkKey($_))))
		{
			--$_;
		}
	}
	return b;
}
SwapTwoSlots(integer currentseatnum, integer newseatnum)
{
	integer OldSlot = (llListFindList(slots, [("seat") + (string)(currentseatnum)]) / (8));
	integer NewSlot = (llListFindList(slots, [("seat") + (string)(newseatnum)]) / (8));

	if((OldSlot != NewSlot) && !(((OldSlot) < 0) || ((OldSlot) > slotMax)) && !(((NewSlot) < 0) || ((NewSlot) > slotMax)))
	{
		key oldslotagent = llList2Key(slots, 4 + 8 * (OldSlot));
		OldSlot *= 8;
		OldSlot += 4;
		slots = llListReplaceList(slots, [llList2Key(slots, 4 + 8 * (NewSlot))], OldSlot, OldSlot);
		NewSlot *= 8;
		NewSlot += 4;
		slots = llListReplaceList(slots, [oldslotagent], NewSlot, NewSlot);
		llMessageLinked(LINK_SET, 35353, llDumpList2String(slots, "^"), NULL_KEY);
	}
}
ProcessLine(string line, key av)
{
	line = llStringTrim(line, STRING_TRIM);
	list params = llParseString2List(line, ["|"], []);
	string action = llList2String(params, 0);

	if("ANIM" == action)
	{
		if(slotMax < lastStrideCount)
		{
			slots = llListReplaceList(slots, [llList2String(params, 1), ((vector)llList2String(params, 2)),
			                                  llEuler2Rot((((vector)llList2String(params, 3))) * DEG_TO_RAD), llList2Key(params, 4), llList2String(slots, (slotMax) * 8 + 4),
			                                  "", "", "seat" + (string)(slotMax + 1)], slotMax * 8, slotMax * 8 + 7);
		}
		else
		{
			slots += [llList2String(params, 1), ((vector)llList2String(params, 2)),
			          llEuler2Rot((((vector)llList2String(params, 3))) * DEG_TO_RAD), llList2String(params, 4), "", "", "", "seat" + (string)(slotMax + 1)];
		}

		slotMax++;
		return;
	}

	if("SINGLE" == action)
	{
		integer posIndex = llListFindList(slots, [((vector)llList2String(params, 2))]);

		if((posIndex == -1) || ((posIndex != -1) && llList2String(slots, posIndex - 1) != llList2String(params, 1)))
		{
			integer slotindex = llListFindList(slots, [clicker]) - 4;
			slots = llListReplaceList(slots, [llList2String(params, 1), ((vector)llList2String(params, 2)),
			                                  llEuler2Rot((((vector)llList2String(params, 3))) * DEG_TO_RAD), llList2String(params, 4),
			                                  llList2Key(slots,
			                                          slotindex + 4), "", "", llList2String(slots, slotindex + 7)], slotindex, slotindex + 7);
			integer newmax = (slotindex + 7 + 8 - 7) / 8;

			if(newmax > slotMax)
			{
				llOwnerSay(llDumpList2String(["(", (61440 - llGetUsedMemory()) >> 10, "kB ) ~>", "slot gap:", newmax - slotMax, "slots", "{", "src/core.lsl", ":", 339, "}"], " "));
				slotMax = newmax;
				lastStrideCount = slotMax;
			}
		}

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
				integer expl = (llList2String(params, 4) == "explicit");
				(status += 2 * (!(status & 2)) * !!(expl) - 2 * (!!(status & 2)) * !(expl));
				vector vDelta = ((vector)llList2String(params, 2));
				vector pos = llGetPos() + (vDelta * llGetRot());
				rotation rot = llEuler2Rot((((vector)llList2String(params, 3))) * DEG_TO_RAD) * llGetRot();

				if(llVecMag(vDelta) > 9.9)
				{
					llRezAtRoot(obj, llGetPos(), ZERO_VECTOR, rot, chatchannel);
					llSleep(1.0);
					llRegionSay(chatchannel, llDumpList2String(["MOVEPROP", obj, (string)pos], "|"));
				}
				else
				{
					llRezAtRoot(obj, llGetPos() + (((vector)llList2String(params, 2)) * llGetRot()), ZERO_VECTOR, rot, chatchannel);
				}
			}
		}

		return;
	}

	if("LINKMSG" == action)
	{
		integer num = llList2Integer(params, 1);
		string line1 = llDumpList2String(llParseStringKeepNulls(line, ["%AVKEY%"], []), av);
		list params1 = llParseString2List(line1, ["|"], []);
		key lmid = llList2Key(params1, 3);

		if(lmid == "")
		{
			lmid = llList2Key(slots, 4 + 8 * (slotMax - 1));
		}

		string str = llList2String(params1, 2);
		llMessageLinked(LINK_SET, num, str, lmid);
		llSleep(1.0);
		llRegionSay(chatchannel, llDumpList2String(["LINKMSGQUE", num, str, lmid], "|"));
		return;
	}

	if("SATMSG" == action)
	{
		integer index = (slotMax - 1) * 8 + 5;
		slots = llListReplaceList(slots, [llDumpList2String([llList2String(slots, index),
		                                  llDumpList2String(llDeleteSubList(params, 0, 0), "|")], "§")], index, index);
		return;
	}

	if("NOTSATMSG" == action)
	{
		integer index = (slotMax - 1) * 8 + 6;
		slots = llListReplaceList(slots, [llDumpList2String([llList2String(slots, index),
		                                  llDumpList2String(llDeleteSubList(params, 0, 0), "|")], "§")], index, index);
	}
}

default
{
	state_entry()
	{
		llOwnerSay("(" + (string)((61440 - llGetUsedMemory()) >> 10) + "kB) ~> " + "repo-npose-91bb8e5d5137f7a3d4d8a5c843d6ad17cb3ab49f 2014-01-31 15:39:50");
		integer n = llGetObjectPrimCount(llGetKey());

		if(!(n))
		{
			llLinkSitTarget(n, <0.0, 0.0, 0.5>, ZERO_ROTATION);
		}

		while(n)
		{
			llLinkSitTarget(n, <0.0, 0.0, 0.5>, ZERO_ROTATION);
			--n;
		}

		chatchannel = (integer)("0x" + llGetSubString((string)llGetKey(), 0, 7));
		llMessageLinked(LINK_SET, 1, (string)chatchannel, NULL_KEY);
		curPrimCount = llGetNumberOfPrims();
		lastPrimCount = curPrimCount;
		llListen(chatchannel, "", NULL_KEY, "");
		card = "";
		integer stop = llGetInventoryNumber(INVENTORY_NOTECARD);

		while(n < stop)
		{
			card = llGetInventoryName(INVENTORY_NOTECARD, n);

			if(!(llSubStringIndex(card, "DEFAULT:") && llSubStringIndex(card, "SET:")))
			{
				llMessageLinked(LINK_SET, 200, card, NULL_KEY);
				return;
			}

			++n;
		}
	}
	link_message(integer sender, integer num, string str, key id)
	{
		if(num == 999999)
		{
			llResetScript();
		}

		if(num == 200)
		{
			card = str;
			clicker = id;
			lastStrideCount = slotMax;
			slotMax = 0;
			llRegionSay(chatchannel, "die");
			llRegionSay(chatchannel, "adjuster_die");
			line = 0;

			if(llGetInventoryKey(card))
			{
				dataid = llGetNotecardLine(card, line);
			}

			return;
		}

		if(num == 207)
		{
			btncard = str;
			clicker = id;
			btnline = 0;
			btnid = llGetNotecardLine(btncard, btnline);
			return;
		}

		if(num == 201)
		{
			(status += 1 * !(status & 1));
			return;
		}

		if(num == 205)
		{
			(status -= 1 * (!!(status & 1)));
			return;
		}

		if(num == 300)
		{
			list msg = llParseString2List(str, ["|"], []);

			if(id != NULL_KEY)
			{
				msg = llListReplaceList(msg, [id], 2, 2);
			}

			llRegionSay(chatchannel, llDumpList2String(["LINKMSG"] + llList2List(msg, 0, 2), "|"));
			return;
		}

		if(num == 202)
		{
			if(!(2 < slotMax))
			{
				list seats2Swap = llParseString2List(str, [","], []);
				SwapTwoSlots(llList2Integer(seats2Swap, 0), llList2Integer(seats2Swap, 1));
			}

			return;
		}

		if(num == 210)
		{
			integer idx = llListFindList(slots, [(id)]) / (8);

			if(!((((idx) < 0) || ((idx) > slotMax))))
			{
				SwapTwoSlots(((integer)llGetSubString(llList2String(slots, 7 + 8 * (idx)), 4, -1)), ((integer)str));
			}

			return;
		}

		if(num == (35353 + 2000000))
		{
			list tempList = llParseStringKeepNulls(str, ["^"], []);
			integer listStop = llGetListLength(tempList) / 8;
			integer slotNum;

			for(slotNum = 0; slotNum < listStop; ++slotNum)
			{
				slots = llListReplaceList(slots, [llList2String(tempList, slotNum * 8), ((vector)llList2String(tempList, slotNum * 8 + 1)),
				                                  ((rotation)llList2String(tempList, slotNum * 8 + 2)), llList2String(tempList, slotNum * 8 + 3),
				                                  llList2Key(tempList, slotNum * 8 + 4), llList2String(tempList, slotNum * 8 + 5),
				                                  llList2String(tempList, slotNum * 8 + 6), llList2String(tempList, slotNum * 8 + 7)], slotNum * 8, slotNum * 8 + 7);
			}

			return;
		}

		if(num == -999 && str == "RezHud")
		{
			if(llGetInventoryType("npose admin hud") != INVENTORY_NONE)
			{
				llRezObject("npose admin hud", llGetPos() + <0, 0, 1>, ZERO_VECTOR, llGetRot(), chatchannel);
			}

			return;
		}

		if(num == -999 && str == "RemoveHud")
		{
			llRegionSayTo(hudId, chatchannel, "/die");
			return;
		}

		if(num == 34334)
		{
			llSay(0, "Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
			return;
		}
	}
	object_rez(key id)
	{
		if(llKey2Name(id) == "npose admin hud")
		{
			hudId = id;
			llSleep(2.0);
			llRegionSayTo(hudId, chatchannel, "parent|" + (string)llGetKey());
		}
	}
	listen(integer channel, string name, key id, string message)
	{
		list temp = llParseString2List(message, ["|"], []);

		if(name == "Adjuster")
		{
			llMessageLinked(LINK_SET, 3, message, id);
			return;
		}

		if(!(llGetListLength(temp) < 2))
		{
			if(name == llKey2Name(hudId))
			{
				list hudcommands = ["adjust", 201, "stopadjust", 205, "posdump", 204, "hudsync", 206];
				integer $_ = llListFindList(hudcommands, [message]);

				if(~$_)
				{
					llMessageLinked(LINK_SET, llList2Integer(hudcommands, $_ + 1), "", "");
				}
			}

			return;
		}

		integer $_0 = (llGetSubString(message, 0, 4) == "ping");
		integer $_1 = (llGetSubString(message, 0, 8) == "PROPRELAY");

		if(($_0 || $_1) && (llGetOwnerKey(id) == llGetOwner()))
		{
			if($_0)
			{
				llRegionSay(chatchannel, "pong|" + (string)(!!(status & 2)) + "|" + (string)llGetPos());
				return;
			}

			if($_1)
			{
				list msg = llParseString2List(message, ["|"], []);
				llMessageLinked(LINK_SET, llList2Integer(msg, 1), llList2String(msg, 2), llList2Key(msg, 3));
				return;
			}

			list params = llParseString2List(message, ["|"], []);
			vector newpos = ((vector)llList2String(params, 0)) - llGetPos();
			newpos /= llGetRot();
			rotation newrot = ((rotation)llList2String(params, 1)) / llGetRot();
			string $_ = "\nPROP|" + name + "|" + (string)newpos + "|" + (string)(llRot2Euler(newrot) * RAD_TO_DEG) + "|" + llList2String(params, 2);
			llRegionSayTo(llGetOwner(), 0, $_);
			llMessageLinked(LINK_SET, 34333, $_, NULL_KEY);
		}
	}
	dataserver(key id, string data)
	{
		if(id == dataid)
		{
			if(!(EOF == data))
			{
				ProcessLine(data, clicker);
				line++;
				dataid = llGetNotecardLine(card, line);
				return;
			}

			if(slotMax < lastStrideCount)
			{
				integer emptySlot;
				emptySlot = 0;

				while((emptySlot < slotMax) && (llList2String(slots, emptySlot * (8) + 4) != ""))
				{
					++emptySlot;
				}

				emptySlot = emptySlot * ((emptySlot != slotMax) - (emptySlot == slotMax)) - !slotMax;
				integer x = slotMax;

				while(x <= lastStrideCount)
				{
					key agent = llList2Key(slots, 4 + 8 * (x));

					if(agent)
					{
						if(!(emptySlot < 0))
						{
							if(sits((key)agent))
							{
								llMessageLinked(LINK_SET, -222, agent, NULL_KEY);
							}
						}
						else
						{
							slots = llListReplaceList(slots, [llList2Key(slots, x * 8 + 4)], emptySlot * 8 + 4, emptySlot * 8 + 4);
							emptySlot = 0;

							while((emptySlot < slotMax) && (llList2String(slots, emptySlot * (8) + 4) != ""))
							{
								++emptySlot;
							}

							emptySlot = emptySlot * ((emptySlot != slotMax) - (emptySlot == slotMax)) - !slotMax;
						}
					}

					++x;
				}

				slots = llDeleteSubList(slots, slotMax * 8, -1);
				lastStrideCount = slotMax;
			}

			llMessageLinked(LINK_SET, 35353, llDumpList2String(slots, "^"), NULL_KEY);

			if((!!(status & 1)))
			{
				llMessageLinked(LINK_SET, 2, "RezAdjuster", "");
			}

			return;
		}

		if((id == btnid) && (data != EOF))
		{
			ProcessLine(data, clicker);
			btnline++;
			btnid = llGetNotecardLine(btncard, btnline);
		}
	}
	changed(integer change)
	{
		if(change & CHANGED_LINK)
		{
			llMessageLinked(LINK_SET, 1, (string)chatchannel, NULL_KEY);
			lastPrimCount = curPrimCount;
			curPrimCount = llGetNumberOfPrims();
			key thisKey = llGetLinkKey(llGetNumberOfPrims());

			if((curPrimCount < lastPrimCount) || !(ZERO_VECTOR != llGetAgentSize(thisKey)))
			{
				integer n = llGetListLength(slots) / 8;

				while(n)
				{
					--n;

					if(!sits(llList2Key(slots, 4 + 8 * (n))))
					{
						slots = llListReplaceList(slots, [""], n * 8 + 4, n * 8 + 4);
					}
				}

				lastPrimCount = curPrimCount;
				llMessageLinked(LINK_SET, 35353, llDumpList2String(slots, "^"), NULL_KEY);
				return;
			}

			if(curPrimCount > lastPrimCount)
			{
				if((!~llListFindList(slots, [thisKey])))
				{
					integer primcount = llGetObjectPrimCount(llGetKey());
					integer n = 1;

					while(n <= primcount)
					{
						integer slotNum = (integer)llGetLinkName(n);

						if((slotNum > 0) && (slotNum <= slotMax))
						{
							if(llAvatarOnLinkSitTarget(n) == thisKey)
							{
								if(llList2Key(slots, 4 + 8 * (slotNum - 1)) == "")
								{
									slots = llListReplaceList(slots, [thisKey], (slotNum - 1) * 8 + 4, (slotNum - 1) * 8 + 4);
								}
							}
						}

						++n;
					}
				}

				if((!~llListFindList(slots, [thisKey])))
				{
					integer freeslot;
					freeslot = 0;

					while((freeslot < slotMax) && (llList2String(slots, freeslot * (8) + 4) != ""))
					{
						++freeslot;
					}

					freeslot = freeslot * ((freeslot != slotMax) - (freeslot == slotMax)) - !slotMax;

					if(freeslot >= 0)
					{
						slots = llListReplaceList(slots, [thisKey], freeslot * 8 + 4, freeslot * 8 + 4);
					}
					else
					{
						if(sits(thisKey))
						{
							llMessageLinked(LINK_SET, -222, (string)thisKey, NULL_KEY);
						}
					}
				}

				llMessageLinked(LINK_SET, 35353, llDumpList2String(slots, "^"), NULL_KEY);
			}
		}

		if(change & CHANGED_INVENTORY)
		{
			llResetScript();
		}

		if(change & CHANGED_REGION)
		{
			llMessageLinked(LINK_SET, 35353, llDumpList2String(slots, "^"), NULL_KEY);
		}
	}
	on_rez(integer param)
	{
		llResetScript();
	}
}

