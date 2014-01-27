// =repo-npose/sat-nosat.i
list slots;
integer chatchannel;
integer seatupdate = 35353;
integer stride = 8;
integer memusage = 34334;
string str_replace(string src, string from, string to)
{
	integer len = (~ -(llStringLength(from)));

	if(~len)
	{
		string buffer = src;
		integer b_pos = -1;
		integer to_len = (~ -(llStringLength(to)));
		@loop;
		integer to_pos = ~llSubStringIndex(buffer, from);

		if(to_pos)
		{
			buffer = llGetSubString(src = llInsertString(llDeleteSubString(src, b_pos -= to_pos, b_pos + len),
			                              b_pos, to), (-~(b_pos += to_len)), 0x8000);
			jump loop;
		}
	}

	return src;
}

default
{
	link_message(integer sender, integer num, string str, key id)
	{
		if(num == 1)
		{
			chatchannel = (integer)str;
		}

		if(num == seatupdate)
		{
			list oldSlots = slots;
			slots = llParseStringKeepNulls(str, ["^"], []);
			list oldstride;
			list currentstride;
			integer n;
			integer stop = llGetListLength(oldSlots) / stride;

			for(n = 0; n < stop; ++n)
			{
				oldstride = llList2List(oldSlots, n * stride, n * stride + 6);
				currentstride = llList2List(slots, n * stride, n * stride + 8);

				if((llList2String(oldstride, 6) != "" && llList2String(oldstride, 4) != ""))
				{
					integer curStrideIndex = llListFindList(slots, [llList2String(oldstride, 4)]) - 4;
					currentstride = llList2List(slots, curStrideIndex, curStrideIndex + 6);

					if((curStrideIndex == -1) || (curStrideIndex != -1 && llList2CSV(oldstride) != llList2CSV(currentstride)))
					{
						integer ndx;
						string nsm = llList2String(oldstride, 6);
						nsm = str_replace(nsm, "%AVKEY%", (key)llList2String(oldstride, 4));
						list smsgs = llParseString2List(nsm, ["�"], []);
						integer msgcnt = llGetListLength(smsgs);

						for(ndx = 0; ndx < msgcnt; ndx++)
						{
							list parts = llParseString2List(llList2String(smsgs, ndx), ["|"], []);
							llMessageLinked(LINK_SET, (integer)llList2String(parts, 0), llList2String(parts, 1),
							                (key)llList2String(oldstride, 4));
							llRegionSay(chatchannel, llDumpList2String(["LINKMSG", (string)llList2String(parts, 0),
							            llList2String(parts, 1), llList2String(oldstride, 4)], "|"));
						}
					}
				}
			}

			stop = llGetListLength(slots) / stride;

			for(n = 0; n < stop; ++n)
			{
				oldstride = llList2List(oldSlots, n * stride, n * stride + 8);
				currentstride = llList2List(slots, n * stride, n * stride + 8);

				if((llList2String(oldstride, 4) == "") && (llList2String(currentstride, 4) != "") && (llList2String(currentstride, 5) != "")
				   || (llList2String(currentstride, 4) != "" && llList2String(currentstride, 5) != ""))
				{
					integer ndx;
					string sm = llList2String(currentstride, 5);
					sm = str_replace(sm, "%AVKEY%", (key)llList2String(currentstride, 4));
					list smsgs = llParseString2List(sm, ["�"], []);
					integer msgcnt = llGetListLength(smsgs);

					for(ndx = 0; ndx < msgcnt; ndx++)
					{
						list parts = llParseString2List(llList2String(smsgs, ndx), ["|"], []);
						llMessageLinked(LINK_SET, (integer)llList2String(parts, 0), llList2String(parts, 1),
						                (key)llList2String(slots, n * stride + 4));
						llSleep(0.1);
						llRegionSay(chatchannel, llDumpList2String(["LINKMSG", (string)llList2String(parts, 0),
						            llList2String(parts, 1), (string)llList2String(slots, n * stride + 4)], "|"));
					}
				}
			}

			return;
		}

		if(num == memusage)
		{
			llOwnerSay(llGetScriptName() + " Memory slated for garbage collection: " + (string)(llGetMemoryLimit() - (llGetFreeMemory() + llGetUsedMemory())));
		}
	}
}

