// For Remilia and Orin's Sunny-Side Up
// ====================================
	
const GAMERULES = "tf_gamerules"
const POPULATOR = "point_populator_interface"

function Init()
{
	local EngyHints =
	[
		// Each entry is an 2D array with 2 more arrays inside
		// 1st among the two is a sentry hint, and the other a nest hint
		// #0
		[
			[Vector(-627, 1502, 64), QAngle(0,-28,0)],
			[Vector(-600, 1717, 64), QAngle(0,-99,0)],
			[Vector(-727, 1364, 64), QAngle(0,-39,0)]
		],
		// #1
		[
			[Vector(-593,  912, 64), QAngle(0,-20,0)],
			[Vector(-779,  796, 64), QAngle(0, 36,0)],
			[Vector(-728, 1000, 64), QAngle(0, 26,0)]
		],
		// #2
		[
			[Vector( 176,  943, 64), QAngle(0,-30,0)],
			[Vector(  19,  853, 64), QAngle(0, 21,0)],
			[Vector( -97,  859, 64), QAngle(0, 94,0)]
		],
		// #3
		[
			[Vector( 131, 1379,  64), QAngle(0, 330,0)],
			[Vector( -68, 1281,  64), QAngle(0,  10,0)],
			[Vector( -40, 1580, 128), QAngle(0, 276,0)]
		],
		// #4
		[
			[Vector(908, 1388, 4), QAngle(0, -63,0)],
			[Vector(777, 1523, 4), QAngle(0, -63,0)],
			[Vector(886, 1535, 4), QAngle(0,-100,0)]
		],
		// #5
		[
			[Vector(-526, -330, 320), QAngle(0,  30,0)],
			[Vector(-656, -621, 320), QAngle(0,  65,0)],
			[Vector(-636,  -18, 256), QAngle(0, 272,0)]
		],
		// #6
		[
			[Vector(-819,  -540, 64), QAngle(0, 15,0), Vector(-764, -414, 64), QAngle(0, -6, 0)],
			[Vector(-1050, -550, 64), QAngle(0,-26,0)],
			[Vector(-1087, -382, 64), QAngle(0,-26,0), Vector(-1160, -481, 64), QAngle(0, 63, 0)]
		],
		// #7
		[
			[Vector(566, -473,64), QAngle(0,48,0), Vector(286,-475,64), QAngle(0,45,0)],
			[Vector(479, -179,64), QAngle(0, -101,0)],
			[Vector(380, -610,64), QAngle(0,   36,0)]
		],
	]
	
	for( local i = 0; i < EngyHints.len(); i++ )
	{
		local hinttypes = EngyHints[i].len()
		local sentry_hintcount = EngyHints[i][0].len() / 2
		
		for( local j = 0; j < sentry_hintcount; j++ )
		{
			local mult = j > 0 ? j * 2 : 0;
			SpawnEntityFromTable("bot_hint_sentrygun", {
				targetname = "remorin_hint_engy"+i,
				origin = EngyHints[i][0][0+mult],
				angles = EngyHints[i][0][1+mult]
			})
		}
		SpawnEntityFromTable("bot_hint_engineer_nest", {
			targetname = "remorin_hint_engy"+i,
			origin = EngyHints[i][1][0],
			angles = EngyHints[i][1][1]
		})
		
		if( hinttypes > 1 )
		{
			local tele_hintcount = EngyHints[i][0].len() / 2
			for( local k = 0; k < tele_hintcount; k++ )
			{
				SpawnEntityFromTable("bot_hint_teleporter_exit", {
					targetname = "remorin_hint_engy"+i,
					origin = EngyHints[i][2][0],
					angles = EngyHints[i][2][1]
				})
			}
		}
	}
	
	// Force this path, we'll use this for the 1st and 2nd wave
	EntFire("bombpath_arrows_clear_relay", "Trigger", null, 1)
	EntFire("bombpath_right", "Trigger", null, 1.1)
	
	// Don't use in final version.
	EnableRedBots()
}

/*****************************************************
	Starts a wave break. CALL FROM POPFILE.
	
	> duration	- Length of break. (Defaults to 35).
	> music		- On break end, play this music. (Defaults to "music/mvm_start_mid_wave.wav").
	> pathrelay	- On break end, fire this relay. (Defaults to "bombpath_choose_relay").
	
*****************************************************/

const COUNTDOWN_20s = "vo/announcer_begins_20sec.mp3"
const COUNTDOWN_10s = "vo/announcer_begins_10sec.mp3"
local StartVOs =
[
	["vo/mvm_general_wav_start01.mp3", 0],
	["vo/mvm_general_wav_start02.mp3", 1],
	["vo/mvm_general_wav_start03.mp3", -1],
	["vo/mvm_general_wav_start07.mp3", -1]
]
local EndVOs =
[
	"vo/mvm_wave_end01.mp3",
	"vo/mvm_wave_end02.mp3",
	"vo/mvm_wave_end07.mp3",
	"vo/mvm_wave_end08.mp3"
]	

function StartWaveBreak(duration = 35, music = "music/mvm_start_mid_wave.wav", pathrelay = "bombpath_choose_relay")
{
	// PATHS
	if ( pathrelay == "Left" )
		pathrelay = "bombpath_left"
	else if ( pathrelay == "Right" )
		pathrelay = "bombpath_right"

	// LOGIC
	EntFire("bombpath_arrows_clear_relay", "Trigger")
	EntFire("bombpath_arrows_clear_relay", "Trigger", null, duration)
	EntFire("upgrade_door_open_relay", "Trigger")
	EntFire("upgrade_door_close_relay", "Trigger", null, duration)
	EntFire( POPULATOR, "PauseBotSpawning")
	EntFire( POPULATOR, "UnpauseBotSpawning", null, duration)
	EntFire("item_teamflag", "ForceReset")

	local size = EndVOs.len() - 1
	local choice = EndVOs[RandomInt(0,size)]
	EntFire( GAMERULES, "PlayVORed", choice, 0)
	EntFire( GAMERULES, "PlayVORed", "Announcer.MVM_Get_To_Upgrade", 5)
	EntFire( pathrelay, "Trigger", 10)
	
	// SOUND
	if( duration >= 35 )
	{
		local delta = (duration - 20)
		EntFire(GAMERULES, "PlayVORed", COUNTDOWN_20s, delta)
	}
	if( duration >= 25 )
	{
		local delta = (duration - 10)
		EntFire(GAMERULES, "PlayVORed", COUNTDOWN_10s, delta)
	}
	if( duration >= 15 )
	{
		local delta = (duration - 5)		
		local size = (StartVOs.len() - 1)
		local choice = RandomInt(0,size)
		local rVO = StartVOs[choice][0]
		local rFixup = StartVOs[choice][1]

		EntFire(GAMERULES, "PlayVORed", rVO, delta + rFixup)
		EntFire(GAMERULES, "PlayVORed", music, delta + rFixup)
	}
}

/*****************************************************
	Collection of functions for switching a boss
	bot's loadout, which is handy for boss patterns
	or boss phases.
	
	Functions:
	1. OnGameEvent_post_inventory_application()
	2. BossInit()
	
*****************************************************/

const TAG_BOSS = "remorin_boss"
ticker <- null
::BOSS <-
{
	// Intended format:
	// [ mvmbot, lastupdatetime ]
	bossbots = []
}

local TF_TEAM_PVE_DEFENDERS = Constants.ETFTeam.TF_TEAM_PVE_DEFENDERS
local TF_TEAM_PVE_INVADERS = Constants.ETFTeam.TF_TEAM_PVE_INVADERS
local MAX_PLAYERS = Constants.Server.MAX_PLAYERS

// Collect any boss robot that spawns for later use
function OnGameEvent_post_inventory_application( params )
{
	local player = GetPlayerFromUserID( params.userid )
	if( player.IsFakeClient() )
	{
		EntFireByHandle(player, "RunScriptCode", "::BOSS.DoBossTag(self)", 0.1, player, player )
	}
}

::BOSS.DoBossTag <- function(bot)
{
	bot.ValidateScriptScope()
	local scope = bot.GetScriptScope()
	if( bot.HasBotTag( TAG_BOSS ) && !("TagAppended" in scope) )
	{
		scope["TagAppended"] <- true
		::BOSS.bossbots.append( [bot, Time()] )
	}
}

::BOSS.ClearBossTags <- function()
{
	for( local i = 0; i < MAX_PLAYERS; i++ )
	{
		local player = GetPlayerFromUserID(i)
		if ( player && player.IsFakeClient() )
		{
			local scope = player.GetScriptScope()
			if( "TagAppended" in scope )
				delete scope["TagAppended"]
		}
	}
	::BOSS.bossbots.clear()
}

// Remove any boss bots that have died - TODO
function OnGameEvent_player_death( params )
{
	local player = GetPlayerFromUserID( params.userid )
	local scope = player.GetScriptScope()
	if( player.IsFakeClient() && ("TagAppended" in scope) )
	{
		for( local i = 0; i < ::BOSS.bossbots.len(); i++ )
		{
			local ary_player = ::BOSS.bossbots[i][0]
			if ( player == ary_player )
			{
				local scope = player.GetScriptScope()
				if( "TagAppended" in scope )
					delete scope["TagAppended"]

				::BOSS.bossbots.remove( i )
			}
		}
	}
}
// Reset all bots we remember as bosses and remove their tags
function OnGameEvent_teamplay_round_win( params )
{
	::BOSS.ClearBossTags()
}

function InitBoss()
{
	::BOSS.ClearBossTags()

	ticker = SpawnEntityFromTable("logic_relay",{
		targetname = "remorin_bossupdate"
	})
	ticker.ValidateScriptScope()
	local scope = ticker.GetScriptScope()
	scope["bossphasecount"] <- 4
	scope["bosspatterncount"] <- 1
	scope["bosschangetime"] <- 10
	scope["bosslastchoice"] <- 1
	scope["BossHPScale"] <- 1.0
	scope["BossDoRun"] <- false
	scope["BossUpdate"] <- function()
	{
		if ( !("BossDoRun" in scope) || !scope["BossDoRun"] )
			return;
		
		for( local i = 0; i < ::BOSS.bossbots.len(); i++ )
		{
			local ary = ::BOSS.bossbots[i]
			local bot = ary[0]
			local lastchangetime = ary[1]
			
			if( Time() > lastchangetime + scope["bosschangetime"] )
			{
				local hp = bot.GetHealth()
				local max_hp = bot.GetMaxHealth()
				this["BossHPScale"] = hp.tofloat() / max_hp.tofloat() // Returns 0 otherwise

				local choice = RandomInt(1,scope["bosspatterncount"])
				if( choice == scope["bosslastchoice"] )
				{
					choice = scope["bosslastchoice"] == 1 ? 2 : choice -= 1;
				}
				
				for ( local j = 1; j <= this["bossphasecount"]; j++ )
				{
					local basehpgate = 1.0 / this["bossphasecount"]
					if ( this["BossHPScale"] <= (basehpgate * j) )
					{
						local phase = this["bossphasecount"]+1 - j
						local loadout = null
						if( choice == 1 && phase == 1 )
						{
							loadout = "Default"
						}
						else
						{
							loadout = format( "Phase%iPattern%i", this["bossphasecount"]+1 - j, choice )
						}
						EntFire( POPULATOR, "ChangeBotAttributes", loadout)
						
						scope["bosslastchoice"] = choice
						::BOSS.bossbots[i][1] = Time()
						break;
					}
				}
			}
		}
		
		return 1.0
	}
	
	AddThinkToEnt(ticker, "BossUpdate")
}

// POPFILE Functions
// -----------------
function RunBossLogic(phasecount, patterncount = 1)
{
	local scope = ticker.GetScriptScope()
	scope["bossphasecount"] = phasecount
	scope["bosspatterncount"] = patterncount
	scope["BossDoRun"] = true
}

// DON'T LOOK
// ----------
function EnableRedBots()
{
	local redflag = Entities.FindByName(null, "orin_redflag")
	if( !redflag )
	{
		redflag = SpawnEntityFromTable("item_teamflag", {
			targetname = "orin_redflag",
			origin = Vector(-627, 1502, 64),
			TeamNum = 2,
			GameType = 1,
			"OnPickup#1": "!self,ForceResetSilent,,0,-1" 
		})
	}
	
	// Timing issue
	// for( local i = 0; i < MAX_PLAYERS; i++ )
	// {
		// local player = GetPlayerFromUserID(i)
		// if ( player && player.IsFakeClient() && player.GetTeam() == TF_TEAM_PVE_DEFENDERS )
		// {
			// local weapon = player.GetActiveWeapon()
			// if ( weapon )
			// {
				// weapon.AddAttribute("damage bonus", 1.5, -1)
				// weapon.AddAttribute("ammo regen", 1, -1)
			// }
		// }
	// }
}

ClearGameEventCallbacks()
Init()
InitBoss()
__CollectGameEventCallbacks(this)