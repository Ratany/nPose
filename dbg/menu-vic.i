// =repo-npose/menu-vic.i
list Permissions = ["Public"];
string curmenuonsit = "off";
string cur2default = "off";
string Facials = "on";
string menuReqSit = "off";
string RLVenabled = "on";
string vicGetsMenu = "off";
key toucherid;
list avs;
list menus;
list menuPerm = [];
string setprefix = "SET";
string btnprefix = "BTN";
string defaultprefix = "DEFAULT";
list cardprefixes = [setprefix, defaultprefix, btnprefix];
list slotbuttons = [];
list dialogids;
integer DIALOG = -900;
integer DIALOG_RESPONSE = -901;
integer DIALOG_TIMEOUT = -902;
integer DOPOSE = 200;
integer ADJUST = 201;
integer SWAP = 202;
integer DUMP = 204;
integer STOPADJUST = 205;
integer SYNC = 206;
integer DOBUTTON = 207;
integer ADJUSTOFFSET = 208;
integer SETOFFSET = 209;
integer SWAPTO = 210;
integer DOMENU = -800;
integer DOMENU_ACCESSCTRL = -801;
integer memusage = 34334;
integer optionsNum = -240;
string FWDBTN = "forward";
string BKWDBTN = "backward";
string LEFTBTN = "left";
string RIGHTBTN = "right";
string UPBTN = "up";
string DOWNBTN = "down";
string ZEROBTN = "reset";
float currentOffsetDelta = 0.2;
list offsetbuttons = [FWDBTN, LEFTBTN, UPBTN, BKWDBTN, RIGHTBTN, DOWNBTN, "0.2", "0.1", "0.05", "0.01", ZEROBTN];
string defaultPose;
string cmdname;
integer curseatednumber = 0;
string SLOTBTN = "ChangeSeat";
string SYNCBTN = "sync";
string OFFSETBTN = "offset";
string BACKBTN = "^";
string ROOTMENU = "Main";
string ADMINBTN = "admin";
string ManageRLV = "ManageRLV";
string ADJUSTBTN = "Adjust";
string STOPADJUSTBTN = "StopAdjust";
string POSDUMPBTN = "PosDump";
string UNSITBTN = "Unsit";
string OPTIONS = "Options";
string MENUONSIT = "Menuonsit";
string TODEFUALT = "ToDefault";
string PERMITBTN = "Permit";
string PUBLIC = "Public";
string LOCKED = "Locked";
string GROUP = "Group";
list victims;
list adminbuttons = [ADJUSTBTN, STOPADJUSTBTN, POSDUMPBTN, UNSITBTN, OPTIONS];
list options = [];
string path;
key Dialog(key rcpt, string prompt, list choices, list utilitybuttons, integer page)
{
	key id = "";

	if(toucherid != llGetOwner() && (menuReqSit == "off"))
	{
		integer stopc = llGetListLength(choices);
		integer nc;

		for(nc = 0; nc < stopc; ++nc)
		{
			integer indexc = llListFindList(menuPerm, [llList2String(choices, nc)]);

			if(indexc != -1)
			{
				if(llList2String(menuPerm, indexc + 1) == "owner")
				{
					choices = llDeleteSubList(choices, nc, nc);
					nc--;
					stopc--;
				}
				else
					if(llList2String(menuPerm, indexc + 1) != "public")
					{
						if(llList2String(menuPerm, indexc + 1) == "group")
						{
							if(llSameGroup(toucherid) != 1)
							{
								choices = llDeleteSubList(choices, nc, nc);
								nc--;
								stopc--;
							}
						}
					}
			}
		}

		id = llHTTPRequest("http://google.com", [HTTP_METHOD, "GET"], "");
		llMessageLinked(LINK_SET, DIALOG, (string)rcpt + "|" + prompt + "|" + (string)page + "|" + llDumpList2String(choices, "`") +
		                "|" + llDumpList2String(utilitybuttons, "`"), id);
	}
	else
		if(((toucherid == llGetOwner()) || (menuReqSit == "off")) || (toucherid != llGetOwner()
		        && menuReqSit == "on" && llListFindList(SeatedAvs(), [(key)toucherid]) != -1))
		{
			id = llHTTPRequest("http://google.com", [HTTP_METHOD, "GET"], "");
			llMessageLinked(LINK_SET, DIALOG, (string)rcpt + "|" + prompt + "|" + (string)page + "|" + llDumpList2String(choices, "`") +
			                "|" + llDumpList2String(utilitybuttons, "`"), id);
		}

	return id;
}
list SeatedAvs()
{
	avs = [];
	integer counter = llGetNumberOfPrims();

	while(llGetAgentSize(llGetLinkKey(counter)) != ZERO_VECTOR)
	{
		avs += [llGetLinkKey(counter)];
		counter--;
	}

	return avs;
}
integer AvCount()
{
	integer stop = llGetNumberOfPrims();
	integer n = stop;

	while(llGetAgentSize(llGetLinkKey(n)) != ZERO_VECTOR)
	{
		n--;
	}

	return stop - n;
}
AdminMenu(key toucher, string path, string prompt, list buttons)
{
	key id = Dialog(toucher, prompt + "\n" + path + "\n", buttons, [BACKBTN], 0);
	integer index = llListFindList(dialogids, [toucher]);
	list addme = [id, toucher, path];

	if(index == -1)
	{
		dialogids += addme;
	}
	else
	{
		dialogids = llListReplaceList(dialogids, addme, index - 1, index + 1);
	}
}
DoMenu(key toucher, string path, string menuPrompt, integer page)
{
	integer index = llListFindList(menus, [path]);

	if(index != -1)
	{
		list buttons = llListSort(llParseStringKeepNulls(llList2String(menus, index + 1), ["|"], []), 1, 1);
		list utility = [];

		if(path != ROOTMENU)
		{
			utility += [BACKBTN];
		}

		key id = Dialog(toucher, menuPrompt + "\n" + path + "\n", buttons, utility, page);
		list addme = [id, toucher, path];
		index = llListFindList(dialogids, [toucher]);

		if(index == -1)
		{
			dialogids += addme;
		}
		else
		{
			dialogids = llListReplaceList(dialogids, addme, index - 1, index + 1);
		}
	}
}
DoMenu_AccessCtrl(key toucher, string path, string menuPrompt, integer page)
{
	integer authorized = FALSE;

	if(toucher == llGetOwner())
	{
		if((llListFindList(victims, [(string)llGetOwner()]) != -1 && vicGetsMenu == "on") || llListFindList(victims, [(string)llGetOwner()]) == -1)
		{
			authorized = TRUE;
		}
	}
	else
		if(((llList2String(Permissions, 0) == GROUP) && (llSameGroup(toucher))) || (llList2String(Permissions, 0) == PUBLIC))
		{
			if(llListFindList(victims, [(string)toucher]) == -1 && vicGetsMenu == "on")
			{
				authorized = TRUE;
			}
		}

	if(authorized)
	{
		DoMenu(toucher, path, menuPrompt, page);
	}
}
BuildMenus()
{
	menus = [];
	menuPerm = [];
	integer stop = llGetInventoryNumber(INVENTORY_NOTECARD);
	integer defaultSet = FALSE;
	integer n;

	for(n = 0; n < stop; ++n)
	{
		string name = llGetInventoryName(INVENTORY_NOTECARD, n);
		integer permsIndex1 = llSubStringIndex(name, "{");
		integer permsIndex2 = llSubStringIndex(name, "}");
		string menuPerms = "";

		if(permsIndex1 != -1)
		{
			menuPerms = llToLower(llGetSubString(name, permsIndex1 + 1, permsIndex2 - 1));
			name = llDeleteSubString(name, permsIndex1, permsIndex2);
		}
		else
		{
			menuPerms = "public";
		}

		list pathParts = llParseStringKeepNulls(name, [":"], []);
		menuPerm += [llList2String(pathParts, -1), menuPerms];
		string prefix = llList2String(pathParts, 0);

		if(!defaultSet && ((prefix == setprefix) || (prefix == defaultprefix)))
		{
			defaultPose = llGetInventoryName(INVENTORY_NOTECARD, n);
			defaultSet = TRUE;
		}

		if(llListFindList(cardprefixes, [prefix]) != -1)
		{
			pathParts = llDeleteSubList(pathParts, 0, 0);

			while(llGetListLength(pathParts))
			{
				string last = llList2String(pathParts, -1);
				string parentpath = llDumpList2String([ROOTMENU] + llDeleteSubList(pathParts, -1, -1), ":");
				integer index = llListFindList(menus, [parentpath]);

				if(index != -1 && !(index % 2))
				{
					list children = llParseStringKeepNulls(llList2String(menus, index + 1), ["|"], []);

					if(llListFindList(children, [last]) == -1)
					{
						children += [last];
						menus = llListReplaceList((menus = []) + menus, [llDumpList2String(children, "|")], index + 1, index + 1);
					}
				}
				else
				{
					menus += [parentpath, last];
				}

				pathParts = llDeleteSubList(pathParts, -1, -1);
			}
		}
	}
}

default
{
	state_entry()
	{
		cmdname = (string)llGetKey();
		BuildMenus();
	}
	touch_start(integer total_number)
	{
		toucherid = llDetectedKey(0);
		DoMenu_AccessCtrl(toucherid, ROOTMENU, "", 0);
	}
	link_message(integer sender, integer num, string str, key id)
	{
		if(num == DIALOG_RESPONSE)
		{
			integer index = llListFindList(dialogids, [id]);

			if(!(~index))
			{
				return;
			}

			list params = llParseString2List(str, ["|"], []);
			integer page = (integer)llList2String(params, 0);
			string selection = llList2String(params, 1);
			path = llList2String(dialogids, index + 2);
			toucherid = llList2Key(dialogids, index + 1);

			if(selection == BACKBTN)
			{
				list pathparts = llParseString2List(path, [":"], []);
				pathparts = llDeleteSubList(pathparts, -1, -1);

				if(llList2String(pathparts, -1) == ADMINBTN)
				{
					AdminMenu(toucherid, llDumpList2String(pathparts, ":"), "", adminbuttons);
				}
				else
					if(llGetListLength(pathparts) <= 1)
					{
						DoMenu(toucherid, ROOTMENU, "", 0);
					}
					else
					{
						DoMenu(toucherid, llDumpList2String(pathparts, ":"), "", 0);
					}

				return;
			}

			if(selection == ADMINBTN)
			{
				path += ":" + selection;
				AdminMenu(toucherid, path, "", adminbuttons);
				return;
			}

			if(selection == SLOTBTN)
			{
				path = path + ":" + selection;
				AdminMenu(toucherid, path, "Where will you sit?", slotbuttons);
				return;
			}

			if(selection == OFFSETBTN)
			{
				path = path + ":" + selection;
				AdminMenu(toucherid, path, "Adjust by " + (string)currentOffsetDelta
				          + "m, or choose another distance.", offsetbuttons);
				return;
			}

			if(selection == ADJUSTBTN)
			{
				llMessageLinked(LINK_SET, ADJUST, "", "");
				AdminMenu(toucherid, path, "", adminbuttons);
				return;
			}

			if(selection == STOPADJUSTBTN)
			{
				llMessageLinked(LINK_SET, STOPADJUST, "", "");
				AdminMenu(toucherid, path, "", adminbuttons);
				return;
			}

			if(selection == POSDUMPBTN)
			{
				llMessageLinked(LINK_SET, DUMP, "", "");
				AdminMenu(toucherid, path, "", adminbuttons);
				return;
			}

			if(selection == UNSITBTN)
			{
				avs = SeatedAvs();
				list buttons;
				integer stop = llGetListLength(avs);
				integer n;

				for(n = 0; n < stop; n++)
				{
					buttons += [llGetSubString(llKey2Name((key)llList2String(avs, n)), 0, 20)];
				}

				if(llGetListLength(buttons) > 0)
				{
					path += ":" + selection;
					AdminMenu(toucherid, path, "Pick an avatar to unsit", buttons);
				}
				else
				{
					AdminMenu(toucherid, path, "", adminbuttons);
				}

				return;
			}

			if(selection == OPTIONS)
			{
				path += ":" + selection;
				string optionsPrompt = "Permit currently set to " + llList2String(Permissions, 0)
				                       + "\nMenuOnSit currently set to " + curmenuonsit + "\nsit2GetMenu currently set to " + menuReqSit
				                       + "\n2default currently set to " + cur2default + "\nFacialEnable currently set to " + Facials
				                       + "\nUseRLVBaseRestrict currently set to " + RLVenabled;
				AdminMenu(toucherid, path, optionsPrompt, options);
				return;
			}

			if(~llListFindList(menus, [path + ":" + selection]))
			{
				path = path + ":" + selection;
				DoMenu(toucherid, path, "", 0);
				return;
			}

			if(llList2String(llParseString2List(path, [":"], []), -1) == SLOTBTN)
			{
				if(llGetSubString(selection, 0, 3) == "seat")
				{
					integer slot = (integer)llGetSubString(selection, 4, -1);

					if(slot >= 0)
					{
						llMessageLinked(LINK_SET, SWAPTO, (string)(slot), toucherid);
					}
				}
				else
				{
					integer slot = llListFindList(slotbuttons, [selection]) + 1;

					if(slot >= 0)
					{
						llMessageLinked(LINK_SET, SWAPTO, (string)(slot), toucherid);
					}
				}

				list pathparts = llParseString2List(path, [":"], []);
				pathparts = llDeleteSubList(pathparts, -1, -1);
				path = llDumpList2String(pathparts, ":");
				DoMenu(toucherid, path, "", 0);
				return;
			}

			if(llList2String(llParseString2List(path, [":"], []), -1) == UNSITBTN)
			{
				integer stop = llGetListLength(avs);
				integer n;

				for(n = 0; n < stop; n++)
				{
					key av = llList2Key(avs, n);

					if(llGetSubString(llKey2Name(av), 0, 20) == selection)
					{
						if(llListFindList(SeatedAvs(), [av]) != -1)
						{
							llMessageLinked(LINK_SET, -222, (string)av, NULL_KEY);
							integer avIndex = llListFindList(avs, [av]);
							avs = llDeleteSubList(avs, index, index);
							n = stop;
						}
					}
				}

				list buttons = [];
				stop = llGetListLength(avs);

				for(n = 0; n < stop; n++)
				{
					buttons += [llGetSubString(llKey2Name((key)llList2String(avs, n)), 0, 20)];
				}

				if(llGetListLength(buttons) > 0)
				{
					AdminMenu(toucherid, path, "Pick an avatar to unsit", buttons);
				}
				else
				{
					list pathParts = llParseString2List(path, [":"], []);
					pathParts = llDeleteSubList(pathParts, -1, -1);
					AdminMenu(toucherid, llDumpList2String(pathParts, ":"), "", adminbuttons);
				}

				return;
			}

			if(llList2String(llParseString2List(path, [":"], []), -1) == OFFSETBTN)
			{
				vector buttons_pos = <(float)(selection == FWDBTN), (float)(selection == LEFTBTN), (float)(selection == UPBTN)>;
				vector buttons_neg = <(float)(selection == BKWDBTN), (float)(selection == RIGHTBTN), (float)(selection == DOWNBTN)>;

				if((llVecMag(buttons_pos) > 1.0) || (llVecMag(buttons_neg) > 1.0))
				{
					llOwnerSay(llDumpList2String(["(", (61440 - llGetUsedMemory()) >> 10, "kB ) ~>", "multiple buttons selected:", buttons_pos, buttons_neg, "{", "src/menu-vic.lsl", ":", 585, "}"], " "));
				}

				vector adjust = buttons_pos - buttons_neg;

				if(adjust)
				{
					vector delta = adjust * currentOffsetDelta;
					llMessageLinked(LINK_SET, ADJUSTOFFSET, (string)delta, toucherid);
				}
				else
				{
					if(selection == ZEROBTN)
					{
						llMessageLinked(LINK_SET, SETOFFSET, (string)ZERO_VECTOR, toucherid);
					}
					else
					{
						currentOffsetDelta = (float)selection;
					}
				}

				AdminMenu(toucherid, path, llDumpList2String(["Adjust by", currentOffsetDelta, "m, or choose another distance."], " "), offsetbuttons);
				return;
			}

			if(selection == SYNCBTN)
			{
				llMessageLinked(LINK_SET, SYNC, "", "");
				DoMenu(toucherid, path, "", page);
				return;
			}

			list pathlist = llDeleteSubList(llParseStringKeepNulls(path, [":"], []), 0, 0);
			integer permission = llListFindList(menuPerm, [selection]);
			string defaultname = llDumpList2String([defaultprefix] + pathlist + [selection], ":");
			string setname = llDumpList2String([setprefix] + pathlist + [selection], ":");
			string btnname = llDumpList2String([btnprefix] + pathlist + [selection], ":");

			if(permission != -1)
			{
				if(llList2String(menuPerm, permission + 1) != "public")
				{
					defaultname += "{" + llList2String(menuPerm, permission + 1) + "}";
					setname += "{" + llList2String(menuPerm, permission + 1) + "}";
					btnname += "{" + llList2String(menuPerm, permission + 1) + "}";
				}
			}

			if(llGetInventoryType(defaultname) == INVENTORY_NOTECARD)
			{
				llMessageLinked(LINK_SET, DOPOSE, defaultname, toucherid);
			}
			else
				if(llGetInventoryType(setname) == INVENTORY_NOTECARD)
				{
					llMessageLinked(LINK_SET, DOPOSE, setname, toucherid);
				}
				else
					if(llGetInventoryType(btnname) == INVENTORY_NOTECARD)
					{
						llMessageLinked(LINK_SET, DOBUTTON, btnname, toucherid);
					}

			if(llGetSubString(selection, -1, -1) == "-")
			{
				llMessageLinked(LINK_SET, -802, path, toucherid);
			}
			else
			{
				DoMenu(toucherid, path, "", page);
			}

			return;
		}

		if(num == DIALOG_TIMEOUT)
		{
			integer index = llListFindList(dialogids, [id]);

			if(index != -1)
			{
				dialogids = llDeleteSubList(dialogids, index, index + 2);
			}

			if(cur2default == "on" && llGetListLength(SeatedAvs()) < 1)
			{
				llMessageLinked(LINK_SET, DOPOSE, defaultPose, NULL_KEY);
			}

			return;
		}

		if(num == optionsNum)
		{
			list optionsToSet = llParseStringKeepNulls(str, ["~"], []);
			integer stop = llGetListLength(optionsToSet);
			integer n = 0;

			while(n < stop)
			{
				list optionsItems = llParseString2List(llList2String(optionsToSet, n), ["="], []);
				string optionItem = llList2String(optionsItems, 0);
				string optionSetting = llList2String(optionsItems, 1);

				if(optionItem == "menuonsit")
				{
					curmenuonsit = optionSetting;
					jump next_item;
				}

				if(optionItem == "permit")
				{
					Permissions = [optionSetting];
					jump next_item;
				}

				if(optionItem == "2default")
				{
					cur2default = optionSetting;
					jump next_item;
				}

				if(optionItem == "sit2getmenu")
				{
					menuReqSit = optionSetting;
					jump next_item;
				}

				if(optionItem == "vicgetsmenu")
				{
					vicGetsMenu = optionSetting;
					jump next_item;
				}

				if(optionItem == "facialExp")
				{
					Facials = optionSetting;
					llMessageLinked(LINK_SET, -241, Facials, NULL_KEY);
					jump next_item;
				}

				if(optionItem == "rlvbaser")
				{
					RLVenabled = optionSetting;
					llMessageLinked(LINK_SET, -1812221819, "RLV=" + RLVenabled, NULL_KEY);
					jump next_item;
				}

				@next_item;
				++n;
			}

			return;
		}

		if(num == -888 && str == ADMINBTN)
		{
			path += ":" + str;
			AdminMenu(toucherid, path, "", adminbuttons);
			return;
		}

		if(num == -888 && str == SLOTBTN)
		{
			path = path + ":" + str;
			AdminMenu(toucherid, path, "Where will you sit?", slotbuttons);
			return;
		}

		if(num == -888 && str == OFFSETBTN)
		{
			path = path + ":" + str;
			AdminMenu(toucherid, path, "Adjust by " + (string)currentOffsetDelta
			          + "m, or choose another distance.", offsetbuttons);
			return;
		}

		if(num == -888 && str == SYNCBTN)
		{
			llMessageLinked(LINK_SET, SYNC, "", "");
			DoMenu(toucherid, path, "", 0);
			return;
		}

		if(num == DOMENU)
		{
			toucherid = id;
			DoMenu(toucherid, str, "", 0);
			return;
		}

		if(num == DOMENU_ACCESSCTRL)
		{
			toucherid = id;
			DoMenu_AccessCtrl(toucherid, ROOTMENU, "", 0);
			return;
		}

		if(num == -238)
		{
			victims = llCSV2List(str);
			return;
		}

		if(num == 35354)
		{
			slotbuttons = llParseString2List(str, [","], []);
			return;
		}

		if(num == memusage)
		{
			llSay(0, "Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
			      + ",Leaving " + (string)llGetFreeMemory() + " memory free.");
		}
	}
	changed(integer change)
	{
		if(change & CHANGED_INVENTORY)
		{
			BuildMenus();
		}

		if(change & CHANGED_OWNER)
		{
			llResetScript();
		}

		avs = SeatedAvs();

		if((change & CHANGED_LINK) && (AvCount() > 0))
		{
			if(curmenuonsit == "on")
			{
				integer lastSeatedAV = llGetListLength(avs);

				if(lastSeatedAV > curseatednumber)
				{
					key id = llList2Key(avs, lastSeatedAV - curseatednumber - 1);
					curseatednumber = lastSeatedAV;

					if(llListFindList(victims, [id]) == -1)
					{
						DoMenu_AccessCtrl(id, ROOTMENU, "", 0);
					}
				}
			}

			curseatednumber = llGetListLength(avs);
		}
		else
			if((change & CHANGED_LINK) && (cur2default == "on"))
			{
				llMessageLinked(LINK_SET, DOPOSE, defaultPose, NULL_KEY);
				curseatednumber = 0;
			}
	}
	on_rez(integer params)
	{
		llResetScript();
	}
}

