
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
#ifdef _STD_DEBUG_PUBLIC
#define fff apf
#else
#define fff opf
#endif
#define DEBUG_virtualShowAnimslist(_l, ...)				\
	{								\
		int $_ = Len(_l) / iSTRIDE_animslist;			\
		LoopDown($_,						\
			 DEBUGmsg("---------- stride:", $_, "of", Len(_l) / iSTRIDE_animslist, "----------"); \
			 DEBUGmsg(__VA_ARGS__, "\n");			\
			 fff("agent:", kAnimslistToAgent(_l, $_));	\
			 fff("cmd  :", sAnimslistToCmd(_l, $_));	\
			 fff("anim :", sAnimslistToAnim(_l, $_))	\
			 );						\
									\
		if(Onlst(_l, llGetOwner()))				\
			{						\
				fff("\towner on list");			\
			}						\
		else							\
			{						\
				fff("\towner NOT on list");		\
			}						\
	}
// 		opf("CSV:", llList2CSV(_l));
#else
#define DEBUG_virtualShowAnimslist(...)
#endif


// list of agent, animation
// holds animations not to stop from playing
//
#define iSTRIDE_lUnstoppable                                2

#define iIDX_lUnstoppable_Agent                             0
#define iIDX_lUnstoppable_Anim                              1

#define kUnstoppableToAgent(_lunstoppable, _stride)         llList2Key(_lunstoppable, _stride * iSTRIDE_lUnstoppable + iIDX_lUnstoppable_Agent)
#define sUnstoppableToAnim(_lunstoppable, _stride)          llList2String(_lunstoppable, _stride * iSTRIDE_lUnstoppable + iIDX_lUnstoppable_Anim)

#define xUnstoppableAdd(_lunstoppable, _agent, _anim)       Enlist(_lunstoppable, _agent, _anim)
#define yUnstoppableRM(_lunstoppable, _stride)              (_lunstoppable = llDeleteSubList(_lunstoppable, _stride * iSTRIDE_lUnstoppable, _stride * iSTRIDE_lUnstoppable + iSTRIDE_lUnstoppable - 1))


// inlineAnimsStopAll(_foragent, _lunstoppable, _do)
//
// stop all animations for agent which are in inventory and not
// in the list of unstoppable animations for that agent
//
#define inlineAnimsStopAll(_foragent, _lunstoppable, _do)		\
	DEBUGmsg1("---------- stopAll ----------");			\
	int slot = LstIdx(slots, _foragent) / stride;			\
					    unless(iIsUndetermined(slot)) \
	{								\
		list notstop = [];					\
		int $_ = Len(_lunstoppable) / iSTRIDE_lUnstoppable;	\
		LoopDown($_,						\
			 when(kUnstoppableToAgent(_lunstoppable, $_) == _foragent) \
			 {						\
				 notstop += sUnstoppableToAnim(_lunstoppable, $_); \
				 llStartAnimation(sUnstoppableToAnim(_lunstoppable, $_)); \
				 DEBUGmsg1("started anim:", sUnstoppableToAnim(_lunstoppable, $_)); \
			 }						\
			 );						\
		DEBUGmsg1("not stopping:", llList2CSV(notstop));	\
									\
		$_ = llGetInventoryNumber(INVENTORY_ANIMATION);		\
									\
		string anim = sSlots2Pose(slot);			\
		LoopDown($_,						\
			 string iname = llGetInventoryName(INVENTORY_ANIMATION, $_); \
			 DEBUGmsg1("\t\tinventory:", llGetInventoryKey(iname), iname); \
			 when(anim != iname)				\
			 {						\
				 if(NotOnlst(notstop, iname))		\
					 {				\
						 llStopAnimation(iname); \
						 DEBUGmsg1("stopping animation:", iname); \
					 }				\
			 }						\
			 );						\
		_do;							\
	}								\
					    else			\
						    {			\
							    ERRORmsg("agent has no slot"); \
						    }			\
	DEBUGmsg1("anims playing:", llList2CSV(llGetAnimationList(_foragent)))



#endif  // _ANIMSLIST
