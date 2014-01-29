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
integer slotMax = 0;
list slots;
integer curPrimCount = 0;
integer lastPrimCount = 0;
integer lastStrideCount;
integer rezadjusters;
integer line;
key dataid;
key clicker;
integer chatchannel;
string card;
integer btnline;
key btnid;
string btncard;
list adjusters;
key hudId;
integer explicitFlag = 0;
integer sits(key k)
{
	integer b;
	{
		integer $_ = llGetNumberOfPrims();
		b = $_;

		while($_ && !(b = !(llGetLinkKey($_) != k)) && (ZERO_VECTOR != llGetAgentSize(llGetLinkKey($_))))
		{
			--$_;
		}
	}
	return b;
}
assignSlots()
{
	if(slotMax < lastStrideCount)
	{
		integer x = slotMax;

		while(x <= lastStrideCount)
		{
			if(llList2Key(slots, x * 8 + 4) != "")
			{
				integer emptySlot = 0;

				while((emptySlot < slotMax) && (llList2String(slots, emptySlot * 8 + 4) != ""))
				{
					++emptySlot;
				}

				emptySlot = emptySlot * ((emptySlot != slotMax) - (emptySlot == slotMax)) - !slotMax;

				if(emptySlot >= 0)
				{
					slots = llListReplaceList(slots, [llList2Key(slots, x * 8 + 4)], emptySlot * 8 + 4, emptySlot * 8 + 4);
				}
			}

			++x;
		}

		slots = llDeleteSubList(slots, slotMax * 8, -1);
		integer n = llGetListLength(slots) / 8;

		while(n)
		{
			--n;

			if(!sits(llList2Key(slots, 4 + 8 * (n))))
			{
				llMessageLinked(LINK_SET, -222, (string)llList2Key(slots, 4 + 8 * (n)), NULL_KEY);
			}
		}
	}

	key thisKey = llGetLinkKey(llGetNumberOfPrims());

	if((curPrimCount > lastPrimCount) && (ZERO_VECTOR != llGetAgentSize(thisKey)))
	{
		integer primcount = llGetObjectPrimCount(llGetKey());
		integer slotNum = -1;
		integer n = 1;

		while(n <= primcount)
		{
			integer x = (integer)llGetLinkName(n);

			if((x > 0) && (x <= slotMax))
			{
				if(llAvatarOnLinkSitTarget(n) == thisKey)
				{
					if(llList2String(slots, (x - 1) * 8 + 4) == "")
					{
						slotNum = x;
					}
				}
			}

			++n;
		}

		for(n = 1; n <= primcount; ++n)
		{
			if(~slotNum && (!~llListFindList(slots, [thisKey])))
			{
				if(slotNum <= slotMax)
				{
					slots = llListReplaceList(slots, [thisKey], (slotNum - 1) * 8 + 4, (slotNum - 1) * 8 + 4);
				}
				else
				{
					llOwnerSay(llDumpList2String(["(", (61440 - llGetUsedMemory()) >> 10, "kB ) ~>", "irregular slot", "{", "src/core.lsl", ":", 325, "}"], " "));
					integer y = 0;

					while((y < slotMax) && (llList2String(slots, y * 8 + 4) != ""))
					{
						++y;
					}

					y = y * ((y != slotMax) - (y == slotMax)) - !slotMax;

					if(y >= 0)
					{
						slots = llListReplaceList(slots, [thisKey], y * 8 + 4, y * 8 + 4);
					}
					else
					{
						if(sits(thisKey))
						{
							llMessageLinked(LINK_SET, -222, (string)thisKey, NULL_KEY);
						}
					}
				}

				n = primcount << 1;
			}

			if((!~llListFindList(slots, [thisKey])))
			{
				integer y = 0;

				while((y < slotMax) && (llList2String(slots, y * 8 + 4) != ""))
				{
					++y;
				}

				y = y * ((y != slotMax) - (y == slotMax)) - !slotMax;

				if(y >= 0)
				{
					slots = llListReplaceList(slots, [thisKey], y * 8 + 4, y * 8 + 4);
				}
				else
				{
					if(sits(thisKey))
					{
						llMessageLinked(LINK_SET, -222, (string)thisKey, NULL_KEY);
					}
				}

				n = primcount << 1;
			}
		}
	}
	else
	{
		if(curPrimCount < lastPrimCount)
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
		}
	}

	lastPrimCount = curPrimCount;
	lastStrideCount = slotMax;
	llMessageLinked(LINK_SET, 35353, llDumpList2String(slots, "^"), NULL_KEY);
}
SwapTwoSlots(integer currentseatnum, integer newseatnum)
{
	if(newseatnum <= slotMax)
	{
		integer OldSlot = llListFindList(slots, ["seat" + (string)currentseatnum]) / 8;
		integer NewSlot = llListFindList(slots, ["seat" + (string)newseatnum]) / 8;
		list curslot = llList2List(slots, NewSlot * 8, NewSlot * 8 + 3)
		               + [llList2Key(slots, OldSlot * 8 + 4)]
		               + llList2List(slots, NewSlot * 8 + 5, NewSlot * 8 + 7);
		slots = llListReplaceList(slots, llList2List(slots, OldSlot * 8, OldSlot * 8 + 3)
		                          + [llList2Key(slots, NewSlot * 8 + 4)]
		                          + llList2List(slots, OldSlot * 8 + 5, OldSlot * 8 + 7), OldSlot * 8, (OldSlot + 1) * 8 - 1);
		slots = llListReplaceList(slots, curslot, NewSlot * 8, (NewSlot + 1) * 8 - 1);
	}
	else
	{
		llRegionSayTo(llList2Key(slots, llListFindList(slots, ["seat" + (string)currentseatnum]) - 4),
		              0, "Seat " + (string)newseatnum + " is not available for this pose set");
	}

	llMessageLinked(LINK_SET, 35353, llDumpList2String(slots, "^"), NULL_KEY);
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
			slots = llListReplaceList(slots, [llList2String(params, 1), llList2Vector(params, 2),
			                                  llEuler2Rot((llList2Vector(params, 3)) * DEG_TO_RAD), llList2Key(params, 4), llList2String(slots, (slotMax) * 8 + 4),
			                                  "", "", "seat" + (string)(slotMax + 1)], slotMax * 8, slotMax * 8 + 7);
		}
		else
		{
			slots += [llList2String(params, 1), llList2Vector(params, 2),
			          llEuler2Rot((llList2Vector(params, 3)) * DEG_TO_RAD), llList2String(params, 4), "", "", "", "seat" + (string)(slotMax + 1)];
		}

		slotMax++;
		return;
	}

	if("SINGLE" == action)
	{
		integer posIndex = llListFindList(slots, [(vector)llList2String(params, 2)]);

		if((posIndex == -1) || ((posIndex != -1) && llList2String(slots, posIndex - 1) != llList2String(params, 1)))
		{
			integer slotindex = llListFindList(slots, [clicker]) - 4;
			slots = llListReplaceList(slots, [llList2String(params, 1), (vector)llList2String(params, 2),
			                                  llEuler2Rot((llList2Vector(params, 3)) * DEG_TO_RAD), llList2String(params, 4),
			                                  llList2Key(slots,
			                                          slotindex + 4), "", "", llList2String(slots, slotindex + 7)], slotindex, slotindex + 7);
		}

		slotMax = llGetListLength(slots) / 8;
		lastStrideCount = slotMax;
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
				if(llList2String(params, 4) == "explicit")
				{
					explicitFlag = 1;
				}
				else
				{
					explicitFlag = 0;
				}

				vector vDelta = (vector)llList2String(params, 2);
				vector pos = llGetPos() + (vDelta * llGetRot());
				rotation rot = llEuler2Rot((llList2Vector(params, 3)) * DEG_TO_RAD) * llGetRot();

				if(llVecMag(vDelta) > 9.9)
				{
					llRezAtRoot(obj, llGetPos(), ZERO_VECTOR, rot, chatchannel);
					llSleep(1.0);
					llRegionSay(chatchannel, llDumpList2String(["MOVEPROP", obj, (string)pos], "|"));
				}
				else
				{
					llRezAtRoot(obj, llGetPos() + ((vector)llList2String(params, 2) * llGetRot()), ZERO_VECTOR, rot, chatchannel);
				}
			}
		}

		return;
	}

	if("LINKMSG" == action)
	{
		integer num = (integer)llList2String(params, 1);
		string line1 = llDumpList2String(llParseStringKeepNulls(line, ["%AVKEY%"], []), av);
		list params1 = llParseString2List(line1, ["|"], []);
		key lmid;

		if((key)llList2String(params1, 3) != "")
		{
			lmid = (key)llList2String(params1, 3);
		}
		else
		{
			lmid = (key)llList2String(slots, (slotMax - 1) * 8 + 4);
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
		llOwnerSay("(" + (string)((61440 - llGetUsedMemory()) >> 10) + "kB) ~> " + "repo-npose-6db4a847178f5ec21219eb3c687aa6af14ca7bc7");
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
		llListen(chatchannel, "", "", "");
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
			adjusters = [];
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
			adjusters = [];
			rezadjusters = TRUE;
			return;
		}

		if(num == 205)
		{
			adjusters = [];
			rezadjusters = FALSE;
			return;
		}

		if(num == 300)
		{
			list msg = llParseString2List(str, ["|"], []);

			if(id != NULL_KEY)
			{
				msg = llListReplaceList((msg = []) + msg, [id], 2, 2);
			}

			llRegionSay(chatchannel, llDumpList2String(["LINKMSG", (string)llList2String(msg, 0),
			            llList2String(msg, 1), (string)llList2String(msg, 2)], "|"));
			return;
		}

		if(num == 202)
		{
			if(llGetListLength(slots) / 8 >= 2)
			{
				list seats2Swap = llParseString2List(str, [","], []);
				SwapTwoSlots((integer)llList2String(seats2Swap, 0), (integer)llList2String(seats2Swap, 1));
			}

			return;
		}

		if(num == 210)
		{
			{
				integer oldseat = (integer)llGetSubString(llList2String(slots, llListFindList(slots, [id]) + 3), 4, -1);

				if(oldseat <= 0)
				{
					llWhisper(0, "avatar is not assigned a slot: " + (string)id);
				}
				else
				{
					SwapTwoSlots(oldseat, (integer)str);
				}
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
				slots = llListReplaceList(slots, [llList2String(tempList, slotNum * 8), (vector)llList2String(tempList, slotNum * 8 + 1),
				                                  (rotation)llList2String(tempList, slotNum * 8 + 2), llList2String(tempList, slotNum * 8 + 3),
				                                  (key)llList2String(tempList, slotNum * 8 + 4), llList2String(tempList, slotNum * 8 + 5),
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
		if(llKey2Name(id) == "Adjuster")
		{
			adjusters += [id];
			return;
		}

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
				llRegionSay(chatchannel, "pong|" + (string)explicitFlag + "|" + (string)llGetPos());
				return;
			}

			if($_1)
			{
				list msg = llParseString2List(message, ["|"], []);
				llMessageLinked(LINK_SET, llList2Integer(msg, 1), llList2String(msg, 2), llList2Key(msg, 3));
				return;
			}

			list params = llParseString2List(message, ["|"], []);
			vector newpos = (vector)llList2String(params, 0) - llGetPos();
			newpos /= llGetRot();
			rotation newrot = llList2Rot(params, 1) / llGetRot();
			string $_ = "\nPROP|" + name + "|" + (string)newpos + "|" + (string)(llRot2Euler(newrot) * RAD_TO_DEG) + "|" + llList2String(params, 2);
			llRegionSayTo(llGetOwner(), 0, $_);
			llMessageLinked(LINK_SET, 34333, $_, NULL_KEY);
		}
	}
	dataserver(key id, string data)
	{
		if(id == dataid)
		{
			if(data == EOF)
			{
				assignSlots();

				if(rezadjusters)
				{
					adjusters = [];
					llMessageLinked(LINK_SET, 2, "RezAdjuster", "");
				}
			}
			else
			{
				ProcessLine(data, clicker);
				line++;
				dataid = llGetNotecardLine(card, line);
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
			assignSlots();
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

