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
// =repo-npose/dialog.i
integer DIALOG = -900;
integer DIALOG_RESPONSE = -901;
integer DIALOG_TIMEOUT = -902;
integer pagesize = 12;
integer memusage = 34334;
string MORE = "More";
string BLANK = " ";
integer timeout = 60;
integer repeat = 5;
list menus;
integer stridelength = 9;
list avs;
list SeatedAvs()
{
	list avs;
	integer linkcount = llGetNumberOfPrims();
	integer n;

	for(n = linkcount; n >= 0; n--)
	{
		key id = llGetLinkKey(n);

		if(llGetAgentSize(id) != ZERO_VECTOR)
		{
			avs = [id] + avs;
		}
		else
		{
			return avs;
		}
	}

	return [];
}
integer RandomUniqueChannel()
{
	integer out = llRound(llFrand(10000000)) + 100000;

	if(~llListFindList(menus, [out]))
	{
		out = RandomUniqueChannel();
	}

	return out;
}
Dialog(key recipient, string prompt, list menuitems, list utilitybuttons, integer page, key id)
{
	string thisprompt = prompt + "(Timeout in 60 seconds.)\n";
	list buttons;
	list currentitems;
	integer numitems = llGetListLength(menuitems + utilitybuttons);
	integer start;
	integer mypagesize;

	if(llList2CSV(utilitybuttons) != "")
	{
		mypagesize = pagesize - llGetListLength(utilitybuttons);
	}
	else
	{
		mypagesize = pagesize;
	}

	if(numitems > pagesize)
	{
		mypagesize--;
		start = page * mypagesize;
		integer end = start + mypagesize - 1;
		currentitems = llList2List(menuitems, start, end);
	}
	else
	{
		start = 0;
		currentitems = menuitems;
	}

	integer stop = llGetListLength(currentitems);
	integer n;

	for(n = 0; n < stop; n++)
	{
		string name = llList2String(menuitems, start + n);
		buttons += [name];
	}

	buttons = SanitizeButtons(buttons);
	utilitybuttons = SanitizeButtons(utilitybuttons);
	integer channel = RandomUniqueChannel();
	integer listener = llListen(channel, "", recipient, "");
	llSetTimerEvent(repeat);

	if(numitems > pagesize)
	{
		llDialog(recipient, thisprompt, PrettyButtons(buttons, utilitybuttons + [MORE]), channel);
	}
	else
	{
		llDialog(recipient, thisprompt, PrettyButtons(buttons, utilitybuttons), channel);
	}

	integer ts = -1;

	if(llListFindList(avs, [recipient]) == -1)
	{
		ts = llGetUnixTime();
	}

	menus += [channel, id, listener, ts, recipient, prompt, llDumpList2String(menuitems, "|"), llDumpList2String(utilitybuttons, "|"), page];
}
list SanitizeButtons(list in)
{
	integer length = llGetListLength(in);
	integer n;

	for(n = length - 1; n >= 0; n--)
	{
		integer type = llGetListEntryType(in, n);

		if(llList2String(in, n) == "")
		{
			in = llDeleteSubList(in, n, n);
		}
		else
			if(type != TYPE_STRING)
			{
				in = llListReplaceList(in, [llList2String(in, n)], n, n);
			}
	}

	return in;
}
list PrettyButtons(list options, list utilitybuttons)
{
	list spacers;
	list combined = options + utilitybuttons;

	while(llGetListLength(combined) % 3 != 0 && llGetListLength(combined) < 12)
	{
		spacers += [BLANK];
		combined = options + spacers + utilitybuttons;
	}

	list out = llList2List(combined, 9, 11);
	out += llList2List(combined, 6, 8);
	out += llList2List(combined, 3, 5);
	out += llList2List(combined, 0, 2);
	return out;
}
list RemoveMenuStride(list menu, integer index)
{
	integer listener = llList2Integer(menu, index + 2);
	llListenRemove(listener);
	return llDeleteSubList(menu, index, index + stridelength - 1);
}
CleanList()
{
	integer length = llGetListLength(menus);
	integer n;

	for(n = length - stridelength; n >= 0; n -= stridelength)
	{
		integer starttime = llList2Integer(menus, n + 3);

		if(starttime == -1)
		{
			key av = (key)llList2String(menus, n + 4);

			if(llListFindList(avs, [av]) == -1)
			{
				menus = RemoveMenuStride(menus, n);
			}
		}
		else
		{
			integer age = llGetUnixTime() - starttime;

			if(age > timeout)
			{
				key id = llList2Key(menus, n + 1);
				llMessageLinked(LINK_SET, DIALOG_TIMEOUT, "", id);
				menus = RemoveMenuStride(menus, n);
			}
		}
	}
}

default
{
	on_rez(integer param)
	{
		llResetScript();
	}
	state_entry()
	{
		avs = SeatedAvs();
	}
	changed(integer change)
	{
		if(change & CHANGED_LINK)
		{
			avs = SeatedAvs();
		}
	}
	link_message(integer sender, integer num, string str, key id)
	{
		if(num == memusage)
		{
			llSay(0, "Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
		}
		else
			if(num == DIALOG)
			{
				list params = llParseStringKeepNulls(str, ["|"], []);
				key rcpt = (key)llList2String(params, 0);
				string prompt = llList2String(params, 1);
				integer page = (integer)llList2String(params, 2);
				list lbuttons = llParseStringKeepNulls(llList2String(params, 3), ["`"], []);
				list ubuttons = llParseStringKeepNulls(llList2String(params, 4), ["`"], []);
				Dialog(rcpt, prompt, lbuttons, ubuttons, page, id);
			}
	}
	listen(integer channel, string name, key id, string message)
	{
		integer menuindex = llListFindList(menus, [channel]);

		if(~menuindex)
		{
			key menuid = llList2Key(menus, menuindex + 1);
			string prompt = llList2String(menus, menuindex + 5);
			list items = llParseStringKeepNulls(llList2String(menus, menuindex + 6), ["|"], []);
			list ubuttons = llParseStringKeepNulls(llList2String(menus, menuindex + 7), ["|"], []);
			integer page = llList2Integer(menus, menuindex + 8);
			menus = RemoveMenuStride(menus, menuindex);

			if(message == MORE)
			{
				page++;
				integer thispagesize = pagesize - llGetListLength(ubuttons) - 1;

				if(page * thispagesize > llGetListLength(items))
				{
					page = 0;
				}

				Dialog(id, prompt, items, ubuttons, page, menuid);
			}
			else
				if(message == BLANK)
				{
					Dialog(id, prompt, items, ubuttons, page, menuid);
				}
				else
				{
					llMessageLinked(LINK_SET, DIALOG_RESPONSE, (string)page + "|" + message, menuid);
				}
		}
	}
	timer()
	{
		CleanList();

		if(!llGetListLength(menus))
		{
			llSetTimerEvent(0.0);
		}
	}
}

