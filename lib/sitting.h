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


//
// This file defines the function sit(), used by both core and slave.
//


// see whether agent _k is sitting on object or not
//
// saves creating a list of all agents in assignSlots()
//
#define inlineIsSitting(_k, _bool)					\
	{								\
		int $_ = llGetNumberOfPrims();				\
		_bool = $_;						\
		while($_ && !(_bool = !(llGetLinkKey($_) != (_k))) && boolIsAgent(llGetLinkKey($_))) \
			{						\
				--$_;					\
			}						\
	}


bool sits(key k)
{
	bool b;
	inlineIsSitting(k, b);
	return b;
}
