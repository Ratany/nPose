
#ifndef _ANIMSLIST
#define _ANIMSLIST

#define iSTRIDE_animslist          3
list animsList;  // agent uuid, string1, string2


#define IDX_animslist_agent        0
#define IDX_animslist_string1      1
#define IDX_animslist_string2      2


#define kAnimslistToAgent(_l, _idx)     llList2Key(_l, (_idx) * (iSTRIDE_animslist) + (IDX_animslist_agent))
#define sAnimslistToCmd(_l, _idx)       llList2String(_l, (_idx) * (iSTRIDE_animslist) + (IDX_animslist_string1))
#define sAnimslistToAnim(_l, _idx)      llList2String(_l, (_idx) * (iSTRIDE_animslist) + (IDX_animslist_string2))
#define yAnimslistDeleteEntry(_l, _idx) (_l = llDeleteSubList(_l, (_idx) * (iSTRIDE_animslist), (_idx) * (iSTRIDE_animslist) + 2))


#ifdef DEBUG_Showanimslist
#define DEBUG_virtualShowAnimslist(_l, ...)				\
	{								\
		int $_ = Len(_l) / iSTRIDE_animslist;			\
		LoopDown($_,						\
			 DEBUGmsg("---------- stride:", $_, "of", Len(_l) / iSTRIDE_animslist, "----------"); \
			 DEBUGmsg(__VA_ARGS__, "\n");			\
			 opf("agent:", kAnimslistToAgent(_l, $_));	\
			 opf("cmd  :", sAnimslistToCmd(_l, $_));	\
			 opf("anim :", sAnimslistToAnim(_l, $_))	\
			 );						\
									\
		if(Onlst(_l, llGetOwner()))				\
			{						\
				opf("\towner on list");			\
			}						\
		else							\
			{						\
				opf("\towner NOT on list");		\
			}						\
	}
// 		opf("CSV:", llList2CSV(_l));
#else
#define DEBUG_virtualShowAnimslist(...)
#endif


// inlineAnimsStopAll(_foragent, _len)
//
// stop all animations for agent and delete all entries of agent from
// animslist
//
// Why can there be empty entries on the animslist?
//
#define inlineAnimsStopAll(_foragent)					\
	{								\
		DEBUGmsg1("---------- stopAll ----------");		\
		int slot = LstIdx(slots, _foragent) / stride;		\
									\
		unless(iIsUndetermined(slot))				\
			{						\
				int $_ = llGetInventoryNumber(INVENTORY_ANIMATION); \
									\
				LoopDown($_,				\
					 string iname = llGetInventoryName(INVENTORY_ANIMATION, $_); \
					 DEBUGmsg1("\t\tinventory:", llGetInventoryKey(iname), iname); \
					 when(sSlots2Pose(slot) != iname) \
					 {				\
						 llStopAnimation(iname); \
						 DEBUGmsg2("stopping animation:", iname); \
					 }				\
					 else				\
						 {			\
							 DEBUGmsg2("--- anim in slot:", iname);	\
						 }			\
					 );				\
			}						\
		else							\
			{						\
				ERRORmsg("agent has no slot");		\
				return;					\
			}						\
		DEBUGmsg1("anims playing:", llList2CSV(llGetAnimationList(_foragent)));	\
	}



#endif  // _ANIMSLIST
