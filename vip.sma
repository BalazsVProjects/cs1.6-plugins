/*
   Ford�totta: BBk
*/

#define DAMAGE_RECIEVED
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
#include <fun>
#include <fakemeta>
#define ADMIN_VIP ADMIN_LEVEL_H

/*
	Fegyvermen� by RsN
*/

const NETOLTS = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))
 
new const g_MaxAmmo[] = 
{
0,
52, //CSW_P228
0, 
90, //CSW_SCOUT
0,  //CSW_HEGRENADE
32,  //CSW_XM1014
0,  //CSW_C4
100,//CSW_MAC10
90, //CSW_AUG
0,  //CSW_SMOKEGRENADE
120,//CSW_ELITE
100,//CSW_FIVESEVEN
100,//CSW_UMP45
90, //CSW_SG550
90, //CSW_GALIL
90, //CSW_FAMAS
100,//CSW_USP
120,//CSW_GLOCK18
30, //CSW_AWP
120,//CSW_MP5NAVY
200,//CSW_M249
32,  //CSW_M3
90, //CSW_M4A1
120,//CSW_TMP
90, //CSW_G3SG1
0,  //CSW_FLASHBANG
35,  //CSW_DEAGLE
90, //CSW_SG552
90, //CSW_AK47
0,  //CSW_KNIFE
100//CSW_P90
}
new orokloszer

public Event_CurWeapon(id)
{
if(get_pcvar_num(orokloszer) == 1)
{
	if(is_user_alive(id))
	{
		new fegyver = read_data(2)
		if( !( NETOLTS & (1<<fegyver) ) ) 
		{
			cs_set_user_bpammo(id, fegyver, g_MaxAmmo[fegyver]);
		}
	}
}
}

// < -------- >

/*
	############
	#CSATLAKOZO#
	############
*/

// <---- ---->

static const COLOR[] = "^x04" //green
static const CONTACT[] = ""
new maxplayers
new gmsgSayText
new mpd, mkb, mhb
new g_MsgSync
new health_add
new health_hs_add
new health_max
new nKiller
new nKiller_hp
new nHp_add
new nHp_max
new g_awp_active
new g_menu_active
new CurrentRound
new bool:HasC4[33]
new pCvar_AdminVIP
new g_steamid[64]
new hasznalt
#define Keysrod (1<<0)|(1<<1)|(1<<9) // Keys: 1234567890
#if defined DAMAGE_RECIEVED
	new g_MsgSync2
#endif

enum {
    SCOREATTRIB_ARG_PLAYERID = 1,
    SCOREATTRIB_ARG_FLAGS
};

enum ( <<= 1 ) {
    SCOREATTRIB_FLAG_NONE = 0,
    SCOREATTRIB_FLAG_DEAD = 1,
    SCOREATTRIB_FLAG_BOMB,
    SCOREATTRIB_FLAG_VIP
};

new bool:g_vanprefix[33], g_prefix[33][100]

public plugin_init()
{
	register_plugin("VIP Eng Version", "3.0", "Dunno")
	mpd = register_cvar("money_per_damage","3")
	mkb = register_cvar("money_kill_bonus","200")
	mhb = register_cvar("money_hs_bonus","500")
	health_add = register_cvar("amx_vip_hp", "15")
	health_hs_add = register_cvar("amx_vip_hp_hs", "30")
	health_max = register_cvar("amx_vip_max_hp", "100")
	g_awp_active = register_cvar("awp_active", "1")
	g_menu_active = register_cvar("menu_active", "1")
	register_event("Damage","Damage","b")
	register_event("DeathMsg","death_msg","a")
	register_menucmd(register_menuid("rod"), Keysrod, "Pressedrod")
	register_clcmd("awp","HandleCmd")
    	register_clcmd("sg550","HandleCmd")
    	register_clcmd("g3sg1","HandleCmd")
	register_clcmd("say /wantvip","ShowMotd")
	
	register_clcmd("say /prefix","prefix", ADMIN_KICK)
	register_concmd("PREFIX", "add_prefix", ADMIN_KICK)
	register_clcmd("say /vipmenu", "menuujra", ADMIN_KICK)
	maxplayers = get_maxplayers()
	gmsgSayText = get_user_msgid("SayText")
	register_clcmd("say", "handle_say")
	register_cvar("amx_contactinfo", CONTACT, FCVAR_SERVER)
	register_logevent("LogEvent_RoundStart", 2, "1=Round_Start" );
	register_event("TextMsg","Event_RoundRestart","a","2&#Game_w")
	register_event("TextMsg","Event_RoundRestart","a","2&#Game_C");
	register_event("DeathMsg", "hook_death", "a", "1>0")
	register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0")
	g_MsgSync = CreateHudSyncObj()
	register_message( get_user_msgid( "ScoreAttrib" ), "MessageScoreAttrib" );
	pCvar_AdminVIP = register_cvar( "amx_adminvip", "1" );
	register_event("CurWeapon" , "Event_CurWeapon" , "be" , "1=1" );
	orokloszer = register_cvar("fm_orokloszer","1")
#if defined DAMAGE_RECIEVED
	g_MsgSync2 = CreateHudSyncObj()
#endif	
}
public prefix(id)
{
if(get_user_flags(id) & ADMIN_KICK)
{
	print_color(id, "Ird be az egyedi prefixed!")
	client_cmd(id, "messagemode PREFIX")
}
else
{
print_color(id, "!g=[MHC]= !yEzt a funkciót csak a !tPrémium VIP !yjoggal rendelkező játékosok használhatják. Bővebb infó !g/vipvasarlas !yparancs.");
}
}
public add_prefix(id)
{	
	g_vanprefix[id] = false
	g_prefix[id] = ""
	
	read_args(g_prefix[id], 99)
	remove_quotes(g_prefix[id])
	
	if((strlen(g_prefix[id]) < 4) || (strlen(g_prefix[id]) > 12))
	{
		g_prefix[id] = ""
		client_cmd(id, "messagemode PREFIX")
		print_color(id, "A prefixed nem lehet rövidebb 4, illetve hosszabb 12 karakternél!")
		return PLUGIN_HANDLED;
	}	
	g_vanprefix[id] = true
	print_color(id, "Az egyedi prefixed: !g%s", g_prefix[id])
		get_user_authid(id, g_steamid, charsmax(g_steamid))
	client_cmd(id, "ap_put s %s %s", g_steamid, g_prefix[id])
	return PLUGIN_HANDLED
}
public on_damage(id)
{
	new attacker = get_user_attacker(id)

#if defined DAMAGE_RECIEVED
	// id should be connected if this message is sent, but lets check anyway
	if ( is_user_connected(id) && is_user_connected(attacker) )
	if (get_user_flags(attacker) & ADMIN_LEVEL_H)
	{
		new damage = read_data(2)

		set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
		ShowSyncHudMsg(id, g_MsgSync2, "%i^n", damage)
#else
	if ( is_user_connected(attacker) && if (get_user_flags(attacker) & ADMIN_LEVEL_H) )
	{
		new damage = read_data(2)
#endif
		set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
		ShowSyncHudMsg(attacker, g_MsgSync, "%i^n", damage)
	}
}

public Damage(id)
{
	new weapon, hitpoint, attacker = get_user_attacker(id,weapon,hitpoint)
	if(attacker<=maxplayers && is_user_alive(attacker) && attacker!=id)
	if (get_user_flags(attacker) & ADMIN_LEVEL_H) 
	{
		new money = read_data(2) * get_pcvar_num(mpd)
		if(hitpoint==1) money += get_pcvar_num(mhb)
		cs_set_user_money(attacker,cs_get_user_money(attacker) + money)
	}
}

public death_msg()
{
	if(read_data(1)<=maxplayers && read_data(1) && read_data(1)!=read_data(2)) cs_set_user_money(read_data(1),cs_get_user_money(read_data(1)) + get_pcvar_num(mkb) - 300)
}

public LogEvent_RoundStart()
{
	CurrentRound++;
	hasznalt = 0
	new players[32], player, pnum;
	get_players(players, pnum, "a");
	for(new i = 0; i < pnum; i++)
	{
		player = players[i];
		if(is_user_alive(player) && get_user_flags(player) & ADMIN_LEVEL_H)
		{
			give_item(player, "weapon_hegrenade")
			give_item(player, "weapon_flashbang")
			give_item(player, "weapon_flashbang")
			give_item(player, "weapon_smokegrenade")
			give_item(player, "item_assaultsuit")
			give_item(player, "item_thighpack")
			
			
			if (!get_pcvar_num(g_menu_active))
				return PLUGIN_CONTINUE
			
			if(CurrentRound >= 0)
			{
				menuteszt(player);
			}
		}
	}
	return PLUGIN_HANDLED
}

public Event_RoundRestart()
{
	CurrentRound=0;
}

public hook_death()
{
   // Killer id
   nKiller = read_data(1)
   
   if ( (read_data(3) == 1) && (read_data(5) == 0) )
   {
      nHp_add = get_pcvar_num (health_hs_add)
   }
   else
      nHp_add = get_pcvar_num (health_add)
   nHp_max = get_pcvar_num (health_max)
   // Updating Killer HP
   if(!(get_user_flags(nKiller) & ADMIN_LEVEL_H))
   return;

   nKiller_hp = get_user_health(nKiller)
   nKiller_hp += nHp_add
   // Maximum HP check
   if (nKiller_hp > nHp_max) nKiller_hp = nHp_max
   set_user_health(nKiller, nKiller_hp)
   // Hud message "Healed +15/+30 hp"
   set_hudmessage(0, 255, 0, -1.0, 0.15, 0, 1.0, 1.0, 0.1, 0.1, -1)
   show_hudmessage(nKiller, "Gyogyulas +%d hp", nHp_add)
   // Screen fading
   message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, nKiller)
   write_short(1<<10)
   write_short(1<<10)
   write_short(0x0000)
   write_byte(0)
   write_byte(0)
   write_byte(200)
   write_byte(75)
   message_end()
 
}

public menuteszt(id)
{
if(get_user_flags(id) & ADMIN_LEVEL_H) {
	Showrod(id);
	}
	else {}
}
public menuujra(id)
{
	if(hasznalt = 0 && get_user_flags(id) & ADMIN_LEVEL_H) {
		Showrod(id);
	}
	else
	{
		if(hasznalt = 1 && get_user_flags(id) & ADMIN_LEVEL_H) {
		print_color(id, "!g=[MHC]= !yEgy körben csak !tegyszer !ytudod aktiválni a Fegyvermenüt!")
		}
		else {
		print_color(id, "!g=[MHC]= !yEzt a funkciót csak a !tPrémium VIP !yjoggal rendelkező játékosok használhatják. Bővebb infó !g/vipvasarlas !yparancs.");
	}
	}
}

public Showrod(id) {
	if(is_user_alive(id) && get_user_flags(id) & ADMIN_LEVEL_H) {
	new menu = menu_create("=[MHC]= VIP Menu", "mh_MyMenu");

	menu_additem(menu, "[Fegyvermenu]", "", 0); // case 0
	menu_additem(menu, "[Prefixmenu]", "", 0); // case 1
	menu_additem(menu, "[Admin Menu]", "", 0, ADMIN_MENU); // case 2

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_NOCOLORS, 1);

	menu_display(id, menu, 0);

	return PLUGIN_HANDLED;
	}

}

public mh_MyMenu(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_cancel(id);
		return PLUGIN_HANDLED;
	}

	new command[6], name[64], access, callback;

	menu_item_getinfo(menu, item, access, command, sizeof command - 1, name, sizeof name - 1, callback);

	switch(item)
	{
		case 0: { Fegyvermenu(id); }
		case 1: { prefix(id); }
		case 2: { print_color(id, "!gEz az opcio jelenleg fejlesztes alatt all!"); }	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public Pressedrod(id, key) {
	/* Menu:
	* VIP Menu
	* 1. Fegvyermen�
	* 2. Egyedi Prefix
	* 0. Exit
	*/
	switch (key) {
		case 0: { 
			Fegyvermenu(id);
			}
		case 1: { 
			prefix(id);
			}
		case 9: { 			
		}
	}
	return PLUGIN_CONTINUE
}

public HandleCmd(id){
	if (!get_pcvar_num(g_awp_active))
      return PLUGIN_CONTINUE
	if(get_user_flags(id) & ADMIN_LEVEL_H) 
		return PLUGIN_CONTINUE
	client_print(id, print_center, "!g=[MHC]= !yEzt a funkciót csak a !tPrémium VIP !yjoggal rendelkező játékosok használhatják. Bővebb infó !g/vipvasarlas !yparancs.")
	return PLUGIN_HANDLED
}

public ShowMotd(id)
{
 show_motd(id, "vip.txt")
}
public client_authorized(id)
{
 set_task(30.0, "PrintText" ,id)
}
public PrintText(id)
{
 print_color(id, "!g[MHC]= !yIrd be !g/wantvip !yes latni fogod, hogyan kaphatsz VIP-t es milyen kivaltsagai vannak.")
}

public handle_say(id) {
	new said[192]
	read_args(said,192)
	if( ( containi(said, "who") != -1 && containi(said, "admin") != -1 ) || contain(said, "/vips") != -1 )
		set_task(0.1,"print_adminlist",id)
	return PLUGIN_CONTINUE
}

public print_adminlist(user) 
{
	new adminnames[33][32]
	new message[256]
	new contactinfo[256], contact[112]
	new id, count, x, len
	
	for(id = 1 ; id <= maxplayers ; id++)
		if(is_user_connected(id))
			if(get_user_flags(id) & ADMIN_LEVEL_H)
				get_user_name(id, adminnames[count++], 31)

	len = format(message, 255, "%s ONLINE VIP: ",COLOR)
	if(count > 0) {
		for(x = 0 ; x < count ; x++) {
			len += format(message[len], 255-len, "%s%s ", adminnames[x], x < (count-1) ? ", ":"")
			if(len > 96 ) {
				print_message(user, message)
				len = format(message, 255, "%s ",COLOR)
			}
		}
		print_message(user, message)
	}
	else {
		len += format(message[len], 255-len, "Nincs jelen VIP.")
		print_message(user, message)
	}
	
	get_cvar_string("amx_contactinfo", contact, 63)
	if(contact[0])  {
		format(contactinfo, 111, "%s Szerver Admin csatlakozik -- %s", COLOR, contact)
		print_message(user, contactinfo)
	}
}

print_message(id, msg[]) {
	message_begin(MSG_ONE, gmsgSayText, {0,0,0}, id)
	write_byte(id)
	write_string(msg)
	message_end()
}

public MessageScoreAttrib( iMsgId, iDest, iReceiver ) {
    if( get_pcvar_num( pCvar_AdminVIP ) ) {
        new iPlayer = get_msg_arg_int( SCOREATTRIB_ARG_PLAYERID );
        
        if( access( iPlayer, ADMIN_VIP ) ) {
            set_msg_arg_int( SCOREATTRIB_ARG_FLAGS, ARG_BYTE, SCOREATTRIB_FLAG_VIP );
        }
    }
}

public Fegyvermenu(id)
{
new CsTeams:userTeam = cs_get_user_team(id)
if(user_has_weapon(id, CSW_C4))
{
	strip_user_weapons(id)
	ham_strip_weapon(id,"weapon_glock18")
	give_item(id, "weapon_knife")
	give_item(id, "weapon_c4")
	cs_set_user_plant(id,1,1)
	new menu = menu_create("\rFegyverMenü", "FegyverMenu_mh");
	menu_additem(menu, "\yM4a1", "0", 0); // case 0
	menu_additem(menu, "\yAk47", "1", 0); // case 1
	menu_additem(menu, "\yAWP", "2", 0); // case 2
	menu_additem(menu, "\yFamas", "3", 0); // case 3
	menu_additem(menu, "\yM249", "4", 0); // case 4
	menu_additem(menu, "\yShotgun M3", "5", 0); // case 5
	menu_additem(menu, "\yShotgun Xm1014", "6", 0); // case 6
	menu_additem(menu, "\yScout", "7", 0); // case 7
	menu_additem(menu, "\yMp5navy", "8", 0); // case 8
	menu_additem(menu, "\yGalil", "9", 0); // case 9
	menu_additem(menu, "\yAug", "10", 0); // case 10
	menu_additem(menu, "\ySG552", "11", 0); // case 11
	menu_additem(menu, "\yP90", "12", 0); // case 12
	menu_additem(menu, "\yTMP", "13", 0); // case 13
	menu_additem(menu, "\yUMP45", "14", 0); // case 14
	menu_additem(menu, "\yMac10", "15", 0); // case 15
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_BACKNAME, "Vissza");
	menu_setprop(menu, MPROP_NEXTNAME, "Előre");
	menu_setprop(menu, MPROP_EXITNAME, "Kilép");
	menu_display(id, menu, 0);	
}
else if (userTeam == CS_TEAM_CT)
{
	strip_user_weapons(id)
	give_item(id, "weapon_knife")
	ham_strip_weapon(id,"weapon_glock18")
	new menu = menu_create("\rFegyverMenü", "FegyverMenu_mh");
	menu_additem(menu, "\yM4a1", "0", 0); // case 0
	menu_additem(menu, "\yAk47", "1", 0); // case 1
	menu_additem(menu, "\yAWP", "2", 0); // case 2
	menu_additem(menu, "\yFamas", "3", 0); // case 3
	menu_additem(menu, "\yM249", "4", 0); // case 4
	menu_additem(menu, "\yShotgun M3", "5", 0); // case 5
	menu_additem(menu, "\yShotgun Xm1014", "6", 0); // case 6
	menu_additem(menu, "\yScout", "7", 0); // case 7
	menu_additem(menu, "\yMp5navy", "8", 0); // case 8
	menu_additem(menu, "\yGalil", "9", 0); // case 9
	menu_additem(menu, "\yAug", "10", 0); // case 10
	menu_additem(menu, "\ySG552", "11", 0); // case 11
	menu_additem(menu, "\yP90", "12", 0); // case 12
	menu_additem(menu, "\yTMP", "13", 0); // case 13
	menu_additem(menu, "\yUMP45", "14", 0); // case 14
	menu_additem(menu, "\yMac10", "15", 0); // case 15
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_BACKNAME, "Vissza");
	menu_setprop(menu, MPROP_NEXTNAME, "Előre");
	menu_setprop(menu, MPROP_EXITNAME, "Kilép");
	menu_display(id, menu, 0);	
}
else if (userTeam == CS_TEAM_T)
{
	strip_user_weapons(id)
	ham_strip_weapon(id,"weapon_usp")
	give_item(id, "weapon_knife")
	give_item(id, "item_thighpack");
	new menu = menu_create("\rFegyverMenü", "FegyverMenu_mh");
	menu_additem(menu, "\yM4a1", "0", 0); // case 0
	menu_additem(menu, "\yAk47", "1", 0); // case 1
	menu_additem(menu, "\yAWP", "2", 0); // case 2
	menu_additem(menu, "\yFamas", "3", 0); // case 3
	menu_additem(menu, "\yM249", "4", 0); // case 4
	menu_additem(menu, "\yShotgun M3", "5", 0); // case 5
	menu_additem(menu, "\yShotgun Xm1014", "6", 0); // case 6
	menu_additem(menu, "\yScout", "7", 0); // case 7
	menu_additem(menu, "\yMp5navy", "8", 0); // case 8
	menu_additem(menu, "\yGalil", "9", 0); // case 9
	menu_additem(menu, "\yAug", "10", 0); // case 10
	menu_additem(menu, "\ySG552", "11", 0); // case 11
	menu_additem(menu, "\yP90", "12", 0); // case 12
	menu_additem(menu, "\yTMP", "13", 0); // case 13
	menu_additem(menu, "\yUMP45", "14", 0); // case 14
	menu_additem(menu, "\yMac10", "15", 0); // case 15
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_BACKNAME, "Vissza");
	menu_setprop(menu, MPROP_NEXTNAME, "Előre");
	menu_setprop(menu, MPROP_EXITNAME, "Kilép");
	menu_display(id, menu, 0);	
}
}

public FegyverMenu_mh(id, menu, item)
{
new command[6], name[64], access, callback;
menu_item_getinfo(menu, item, access, command, sizeof command - 1, name, sizeof name - 1, callback);
switch(item)
{
	case 0: 
	{
		give_item(id, "weapon_m4a1");
		give_item(id, "ammo_556nato");
		give_item(id, "ammo_556nato");
		give_item(id, "ammo_556nato");
		give_item(id, "weapon_knife"); 
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 1:
	{
		give_item(id, "weapon_ak47");
		give_item(id, "ammo_762nato");
		give_item(id, "ammo_762nato");
		give_item(id, "ammo_762nato");
		give_item(id, "weapon_knife");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 2: 
	{
		give_item(id, "weapon_awp");
		give_item(id, "ammo_338magnum");
		give_item(id, "ammo_338magnum");      
		give_item(id, "ammo_338magnum");
		give_item(id, "weapon_knife");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 3: 
	{
		give_item(id, "weapon_famas");
		give_item(id, "ammo_556nato");
		give_item(id, "ammo_556nato");
		give_item(id, "ammo_556nato");
		give_item(id, "ammo_556nato");
		give_item(id, "weapon_knife");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 4: 
	{
		give_item(id, "weapon_m249");
		give_item(id, "ammo_556nato");
		give_item(id, "ammo_556nato");
		give_item(id, "weapon_knife");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 5: 
	{
		give_item(id, "weapon_m3");
		give_item(id, "ammo_buckshot");
		give_item(id, "ammo_buckshot");
		give_item(id, "ammo_buckshot");
		give_item(id, "weapon_knife");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 6: 
	{
		give_item(id, "weapon_xm1014");
		give_item(id, "ammo_buckshot");
		give_item(id, "ammo_buckshot");
		give_item(id, "ammo_buckshot");
		give_item(id, "ammo_buckshot");
		give_item(id, "weapon_knife");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 7: 
	{
		give_item(id, "weapon_scout");
		give_item(id, "ammo_762nato");
		give_item(id, "ammo_762nato");
		give_item(id, "ammo_762nato");
		give_item(id, "ammo_762nato");
		give_item(id, "ammo_762nato");
		give_item(id, "ammo_762nato");
		give_item(id, "ammo_762nato");
		give_item(id, "ammo_762nato");
		give_item(id, "ammo_762nato");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 8: 
	{
		give_item(id, "weapon_mp5navy");
		give_item(id, "ammo_9mm");
		give_item(id, "ammo_9mm");
		give_item(id, "ammo_9mm");
		give_item(id, "ammo_9mm");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 9: 
	{
		give_item(id, "weapon_galil");
		give_item(id, "ammo_556nato");
		give_item(id, "ammo_556nato");
		give_item(id, "ammo_556nato");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 10: 
	{
		give_item(id, "weapon_aug");
		give_item(id, "ammo_556nato");
		give_item(id, "ammo_556nato");
		give_item(id, "ammo_556nato");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 11:
	{
		give_item(id, "weapon_sg552");
		give_item(id, "ammo_556nato");
		give_item(id, "ammo_556nato");
		give_item(id, "ammo_556nato");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 12: 
	{
		give_item(id, "weapon_p90");
		give_item(id, "ammo_57mm");
		give_item(id, "ammo_57mm");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 13: 
	{
		give_item(id, "weapon_tmp");
		give_item(id, "ammo_9mm");
		give_item(id, "ammo_9mm");
		give_item(id, "ammo_9mm");
		give_item(id, "ammo_9mm");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 14: 
	{
		give_item(id, "weapon_ump45");
		give_item(id, "ammo_45acp");
		give_item(id, "ammo_45acp");
		give_item(id, "ammo_45acp");
		give_item(id, "ammo_45acp");
		give_item(id, "weapon_knife");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
	case 15: 
	{
		give_item(id, "weapon_mac10");
		give_item(id, "ammo_45acp");
		give_item(id, "ammo_45acp");
		give_item(id, "ammo_45acp");
		give_item(id, "ammo_45acp");
		give_item(id, "item_assaultsuit");
		hasznalt + 1;
		PistolMenu(id);
	}
}
 
menu_destroy(menu);
 
return PLUGIN_HANDLED;
}
public PistolMenu(id)
{
new menu = menu_create("\rPisztolyMenü", "PistolMenu_mh");
 
menu_additem(menu, "\yDeagle", "", 0); // case 0
menu_additem(menu, "\yUsp", "", 0); // case 1
menu_additem(menu, "\yGlock18", "", 0); // case 2
menu_additem(menu, "\yP228", "", 0); // case 3
menu_additem(menu, "\yFiveseven", "", 0); // case 4
menu_additem(menu, "\yElite", "", 0); // case 5
 
menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
menu_setprop(menu, MPROP_BACKNAME, "Vissza");
menu_setprop(menu, MPROP_NEXTNAME, "Előre");
menu_setprop(menu, MPROP_EXITNAME, "Kilép");
 
menu_display(id, menu, 0);
 
return PLUGIN_HANDLED;
}
 
public PistolMenu_mh(id, menu, item)
{
if(item == MENU_EXIT)
{
	menu_cancel(id);
	return PLUGIN_HANDLED;
}
 
new command[6], name[64], access, callback;
 
menu_item_getinfo(menu, item, access, command, sizeof command - 1, name, sizeof name - 1, callback);
 
switch(item)
{
	case 0: 
	{
		give_item(id, "weapon_deagle");
		give_item(id,"ammo_50ae");
		give_item(id,"ammo_50ae");
		give_item(id,"ammo_50ae");
		give_item(id,"ammo_50ae");
		give_item(id,"ammo_50ae");
		give_item(id, "weapon_hegrenade");
		give_item(id, "weapon_flashbang");
		give_item(id, "weapon_flashbang");
		cs_set_user_bpammo(id, CSW_HEGRENADE, 1)
	}
	case 1:
	{
		give_item(id, "weapon_usp");
		give_item(id,"ammo_45acp");
		give_item(id,"ammo_45acp");
		give_item(id,"ammo_45acp");
		give_item(id,"ammo_45acp");
		give_item(id,"ammo_45acp");
		give_item(id,"ammo_45acp");
		give_item(id,"ammo_45acp");
		give_item(id,"ammo_45acp");
		give_item(id,"ammo_45acp");
		give_item(id, "weapon_hegrenade");
		give_item(id, "weapon_flashbang");
		give_item(id, "weapon_flashbang");
		cs_set_user_bpammo(id, CSW_HEGRENADE, 1)
	}
	case 2: 
	{
		give_item(id, "weapon_glock18");
		give_item(id,"ammo_9mm");
		give_item(id,"ammo_9mm");
		give_item(id,"ammo_9mm");
		give_item(id,"ammo_9mm");
		give_item(id,"ammo_9mm");
		give_item(id,"ammo_9mm");
		give_item(id, "weapon_hegrenade");
		give_item(id, "weapon_flashbang");
		give_item(id, "weapon_flashbang");
		cs_set_user_bpammo(id, CSW_HEGRENADE, 1)
	}
	case 3: 
	{
		give_item(id, "weapon_p228");
		give_item(id,"ammo_357sig");
		give_item(id,"ammo_357sig");
		give_item(id,"ammo_357sig");
		give_item(id,"ammo_357sig");
		give_item(id, "weapon_hegrenade");
		give_item(id, "weapon_flashbang");
		give_item(id, "weapon_flashbang");
		cs_set_user_bpammo(id, CSW_HEGRENADE, 1)
	}
	case 4: 
	{
		give_item(id, "weapon_fiveseven");
		give_item(id,"ammo_57mm");
		give_item(id,"ammo_57mm");
		give_item(id,"ammo_57mm");
		give_item(id,"ammo_57mm");
		give_item(id,"ammo_57mm");
		give_item(id, "weapon_hegrenade");
		give_item(id, "weapon_flashbang");
		give_item(id, "weapon_flashbang");
		cs_set_user_bpammo(id, CSW_HEGRENADE, 1)
	}
	case 5: 
	{
		give_item(id, "weapon_elite");
		give_item(id,"ammo_9mm");
		give_item(id,"ammo_9mm");
		give_item(id,"ammo_9mm");
		give_item(id,"ammo_9mm");
		give_item(id, "weapon_hegrenade");
		give_item(id, "weapon_flashbang");
		give_item(id, "weapon_flashbang");
		cs_set_user_bpammo(id, CSW_HEGRENADE, 1)
	}
}
menu_destroy(menu);
return PLUGIN_HANDLED;
}
stock ham_give_weapon(id,weapon[])
{
	if(!equal(weapon,"weapon_",7)) return 0;
 
	new wEnt = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,weapon));
	if(!pev_valid(wEnt)) return 0;
 
	set_pev(wEnt,pev_spawnflags,SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn,wEnt);
 
	if(!ExecuteHamB(Ham_AddPlayerItem,id,wEnt))
	{
		if(pev_valid(wEnt)) set_pev(wEnt,pev_flags,pev(wEnt,pev_flags) | FL_KILLME);
		return 0;
	}
	ExecuteHamB(Ham_Item_AttachToPlayer,wEnt,id)
	return 1;
}
stock ham_strip_weapon(id,weapon[])
{
	if(!equal(weapon,"weapon_",7)) return 0;
 
	new wId = get_weaponid(weapon);
	if(!wId) return 0;
 
	new wEnt;
	while((wEnt = engfunc(EngFunc_FindEntityByString,wEnt,"classname",weapon)) && pev(wEnt,pev_owner) != id) {}
	if(!wEnt) return 0;
 
	if(get_user_weapon(id) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon,wEnt);
 
	if(!ExecuteHamB(Ham_RemovePlayerItem,id,wEnt)) return 0;
	ExecuteHamB(Ham_Item_Kill,wEnt);
 
	set_pev(id,pev_weapons,pev(id,pev_weapons) & ~(1<<wId));
	return 1;
}
 
stock print_color(const id, const input[], any:...)
{
        new count = 1, players[32]
        static msg[191]
        vformat(msg, 190, input, 3)
 
        replace_all(msg, 190, "!g", "^4")
        replace_all(msg, 190, "!y", "^1")
        replace_all(msg, 190, "!t", "^3")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")
        replace_all(msg, 190, "?", "�")       
 
        if (id) players[0] = id; else get_players(players, count, "ch")
        {
                for (new i = 0; i < count; i++)
                {
                        if (is_user_connected(players[i]))
                        {
                                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
                                write_byte(players[i])
                                write_string(msg)
                                message_end()
                        }
                }
        }
        return PLUGIN_HANDLED
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1063\\ f0\\ fs16 \n\\ par }
*/
