// For Remilia and Orin's Sunny-Side Up
// ====================================
	
const GAMERULES = "tf_gamerules"
const POPULATOR = "point_populator_interface"
const POPFILE   = "exp_sunny_side_up"

local TF_TEAM_PVE_DEFENDERS = Constants.ETFTeam.TF_TEAM_PVE_DEFENDERS
local TF_TEAM_PVE_INVADERS = Constants.ETFTeam.TF_TEAM_PVE_INVADERS
local MAX_PLAYERS = Constants.Server.MAX_PLAYERS

::ORIN <- {}
::OBJECTIVE <- null
::POPNAME <- null

function Init()
{
	::OBJECTIVE <- Entities.FindByClassname(null, "tf_objective_resource")
	local popname =  NetProps.GetPropString(::OBJECTIVE, "m_iszMvMPopfileName")
	::POPNAME <- popname.slice(39,popname.len()-4)
	
	// Run any functions that should be ran on popfile init.
	InitTags()
	InitFlankers()
	InitBoss()
	DoEngyHints()
	
	// For gameplay purposes, always force this path on popfile load.
	// This is for the 1st and 2nd wave.
	EntFire("bombpath_arrows_clear_relay", "Trigger", null, 1)
	EntFire("bombpath_clearall_relay", "Trigger", null, 1)
	EntFire("bombpath_right", "Trigger", null, 1.1)
	
	// Don't use in final version; this is just for internal amusement.
	if( developer() )
		DoRedBots()
}

// This is for removing game events when the mission has changed
::ORIN.CheckEvents <- function(ref, eventary)
{
	if( ::POPNAME == POPFILE )
		return;
	
	foreach( name in eventary )
	{
		local callbacks = GameEventCallbacks[name]
		for( local i = 0; i < callbacks.len(); i++ )
		{
			if( "ref" in callbacks[i] && callbacks[i]["ref"] == ref )
			{
				GameEventCallbacks[name].remove(i)
			}
		}
	}
}

/*****************************************************
	ENGINEER HINTS
	
	Coastrock does not support engineer bots, so hints
	are required to be made.

	No popfile functions.
	
*****************************************************/

function DoEngyHints()
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
			[Vector(-740,  -71, 256), QAngle(0,  60,0)],
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
			local step = j > 0 ? j * 2 : 0;
			SpawnEntityFromTable("bot_hint_sentrygun", {
				targetname = "remorin_hint_engy"+i,
				origin = EngyHints[i][0][0+step],
				angles = EngyHints[i][0][1+step]
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
}

/*****************************************************
	FLANKER PATHS
	
`	Little role is given to the "fkanker" tag, and some
	paths that should be flanker-only are free to be
	used by non-flankers on "SeekAndDestroy" behaviour.

	No popfile functions.
	
*****************************************************/

::FLANKERS <- { ref = "FLANKERS" }

function InitFlankers()
{
	// Handle mapper-placed nav entities we don't like.
	for ( local ent; ent = Entities.FindByClassname(ent, "func_nav*"); )
	{
		// "nav_flankbot_right"
		local hammerid = NetProps.GetPropInt(ent, "m_iHammerID")
		if( hammerid == 7981 )
			ent.Kill()
	}
	for ( local ent; ent = Entities.FindByClassname(ent, "func_nav_avoid"); )
	{
		// Unnamed nav_avoid @ left of hatch
		local hammerid = NetProps.GetPropInt(ent, "m_iHammerID")
		if( hammerid == 325017 )
		{
			ent.KeyValueFromInt("team", 3)
			ent.KeyValueFromString("tags", "common bomb_carrier giant")
		}
		else
		{
			ent.KeyValueFromInt("team", 3)
		}
	}
	
	// Our nav entities, according to our LMP file:
	local NavEnts =
	[
		// Each entry is an 2D array, with another array and a dictionary inside.
		// 1st is the bbox min and max respective, whereas 2nd is the keyvalues.
		
		// AVOIDS
		// #0
		[
			[Vector(-320,-528,-32), Vector(320,528,32)],
			{
				classname = "func_nav_avoid",
				origin = Vector(960, 1056, 32),
				targetname = "nav_avoid_left",
				tags = "common bomb_carrier"
			}
		],
		// #1
		[
			[Vector(-208,-72,-128), Vector(208,72,128)],
			{
				classname = "func_nav_avoid",
				origin = Vector(-288, -712, 192),
				targetname = "orin_avoid",
				tags = "common bomb_carrier"
			}
		],
		// #2
		[
			[Vector(-232,-296,-120), Vector(232,296,120)],
			{
				classname = "func_nav_avoid",
				origin = Vector(440, -392, 184),
				targetname = "orin_flank_avoid",
				tags = "flankbot"
			}
		],
		// #3
		[
			[Vector(-160,-352,-144), Vector(160,352,144)],
			{
				classname = "func_nav_avoid",
				origin = Vector(-352, 416, 144),
				targetname = "orin_flank_avoid_right",
				tags = "flankbot"
			}
		],
		// #4
		[
			[Vector(-320,-528,-32), Vector(320,528,32)],
			{
				classname = "func_nav_avoid",
				origin = Vector(960, 1056, 32),
				targetname = "orin_flank_avoid_left",
				tags = "flankbot"
			}
		],
		
		// PREFERS
		// #0
		[
			[Vector(-160,-432,-160), Vector(160,432,160)],
			{
				classname = "func_nav_prefer",
				origin = Vector(-672, -368, 400),
				targetname = "orin_flank_prefer",
				tags = "flankbot"
			}
		],
		// #1
		[
			[Vector(-1416,-188,-128), Vector(1416,188,128)],
			{
				classname = "func_nav_prefer",
				origin = Vector(568, -928, 432),
				targetname = "orin_flank_prefer",
				tags = "flankbot"
			}
		],
		// #2
		[
			[Vector(-344,-423.5,-144), Vector(344,423.5,144)],
			{
				classname = "func_nav_prefer",
				origin = Vector(-136, -360, 208),
				targetname = "orin_flank_prefer",
				tags = "flankbot"
			}
		],
		// #3
		[
			[Vector(-160,-352,-144), Vector(160,352,144)],
			{
				classname = "func_nav_prefer",
				origin = Vector(-352, 416, 144),
				targetname = "orin_flank_prefer_left",
				tags = "flankbot"
			}
		],
		// #4
		[
			[Vector(-224,-320,-208), Vector(224,320,208)],
			{
				classname = "func_nav_prefer",
				origin = Vector(432, 464, 16),
				targetname = "orin_flank_prefer_right",
				tags = "flankbot"
			}
		],
		// #5
		[
			[Vector(-520,-360,-167.5), Vector(520,360,167.5)],
			{
				classname = "func_nav_prefer",
				origin = Vector(-328, 424, -120),
				targetname = "orin_flank_prefer_right",
				tags = "flankbot"
			}
		],
		// #6
		[
			[Vector(-224,-408,-240), Vector(224,408,240)],
			{
				classname = "func_nav_prefer",
				origin = Vector(-1072, 104, 48),
				targetname = "orin_flank_prefer_right",
				tags = "flankbot"
			}
		],
		// #7
		[
			[Vector(-384,-168,-112), Vector(384,168,112)],
			{
				classname = "func_nav_prefer",
				origin = Vector(-896, -472, 176),
				targetname = "orin_flank_prefer_right",
				tags = "flankbot"
			}
		]
	]
	
	for( local i = 0; i < NavEnts.len(); i++ )
	{
		local mins = NavEnts[i][0][0]
		local maxs = NavEnts[i][0][1]
		local kvs  = NavEnts[i][1]

		local prefer = SpawnEntityFromTable(kvs.classname, kvs)
		prefer.SetSize(mins, maxs)
		prefer.SetSolid(2)
		
		// Show the brushes when I/O dev mode (2) is active
		if( developer() > 1 )
		{
			if( kvs.classname == "func_nav_avoid" )
				DebugDrawBox( kvs.origin, mins, maxs, 200, 0, 0, 50, 300 )
			else if( kvs.classname == "func_nav_prefer" )
				DebugDrawBox( kvs.origin, mins, maxs, 0, 200, 0, 50, 300 )
			
			local name = format("%s (#%i)", "targetname" in kvs ? kvs.targetname : kvs.classname, i )
			DebugDrawText( kvs.origin, name, false, 300 )
		}
	}
	
	// Finalise it all.
	local bombpath_left  = Entities.FindByName(null, "bombpath_left")
	local bombpath_right = Entities.FindByName(null, "bombpath_right")
	local bombpath_clearall_relay = Entities.FindByName(null, "bombpath_clearall_relay")
	
	EntityOutputs.AddOutput(bombpath_left, "OnTrigger", "orin_flank_prefer_left", "Enable", null, 0, -1)
	EntityOutputs.AddOutput(bombpath_left, "OnTrigger", "orin_flank_avoid_left", "Enable", null, 0, -1)
	EntityOutputs.AddOutput(bombpath_right, "OnTrigger", "orin_flank_prefer_right", "Enable", null, 0, -1)
	EntityOutputs.AddOutput(bombpath_right, "OnTrigger", "orin_flank_avoid_right", "Enable", null, 0, -1)
	
	EntityOutputs.AddOutput(bombpath_clearall_relay, "OnTrigger", "orin_flank_avoid_left", "Disable", null, 0, -1)
	EntityOutputs.AddOutput(bombpath_clearall_relay, "OnTrigger", "orin_flank_avoid_right", "Disable", null, 0, -1)
	EntityOutputs.AddOutput(bombpath_clearall_relay, "OnTrigger", "orin_flank_prefer_left", "Disable", null, 0, -1)
	EntityOutputs.AddOutput(bombpath_clearall_relay, "OnTrigger", "orin_flank_prefer_right", "Disable", null, 0, -1)
	
	__CollectGameEventCallbacks(::FLANKERS)
}

::FLANKERS.OnGameEvent_mvm_begin_wave <- function( params )
{
	DebugDrawClear()
}

::FLANKERS.OnGameEvent_teamplay_round_start <- function( params )
{
	local events =
	[
		"mvm_begin_wave",
		"teamplay_round_start"
	]

	::ORIN.CheckEvents("FLANKERS", events)
}

/*****************************************************
	WAVE BRREAKS
	
	A core trait of endurance missions is breaking itself
	into parts using wave breaks.

	Functions:
	> StartWaveBreak(duration, music, pathrelay)
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
	BOT TAGS

	A cute interface for storing robots with bot tags
	that we care for.
	
*****************************************************/
::TAGS <- { ref = "TAGS" }

function InitTags()
{
	__CollectGameEventCallbacks(::TAGS)
}

::TAGS.RegisterBot <- function(bot, tagname, ary)
{
	if( bot.IsFakeClient() )
	{
		bot.ValidateScriptScope()
		local scope = bot.GetScriptScope()
		if( bot.HasBotTag( tagname ) && !(tagname in scope) )
		{
			scope[tagname] <- true
			ary.append( [bot, Time()] )
		}
	}
}

// Remove dead tagged bots from our arrays.
::TAGS.UnregisterBot <- function(bot, tagname, ary)
{
	bot.ValidateScriptScope()
	local scope = bot.GetScriptScope()
	if( bot.IsFakeClient() && (tagname in scope) )
	{
		for( local i = 0; i < ary.len(); i++ )
		{
			local ary_player = ary[i][0]
			if ( bot == ary_player )
			{
				if( tagname in scope )
					delete scope[tagname]

				ary.remove( i )
			}
		}
	}
}

// For round ends.
::TAGS.ClearBots <- function(tagname, ary)
{
	for( local i = 0; i < MAX_PLAYERS; i++ )
	{
		local player = GetPlayerFromUserID(i)
		if ( player && player.IsFakeClient() )
		{
			local scope = player.GetScriptScope()
			if( tagname in scope )
				delete scope[tagname]
		}
	}
	ary.clear()
}

// We ought to clean our waste responsibly.
::TAGS.OnGameEvent_teamplay_round_start <- function( params )
{
	local events =
	[
		"teamplay_round_start"
	]

	::ORIN.CheckEvents("BOSS", events)
}

/*****************************************************
	BOSS PATTERNS
	
	The boss behaviour featured prominently in Winterbridge
	and Silent Sky, where bosses swap loadouts depending either
	on health or a timer.

	Functions:
	> RunBossLogic(phasecount, patterncount)
	Runs through all bots and collect any with the boss tag.
	
	> phasecount - Amount of health phases to use.
	> patterncount - Amount of loadouts per each phase.
	
	Boss bots need an "EventChangeAttributes" block with
	attribute blocks for each phases and patterns you
	will be using; running the boss logic with 2 phases
	and 2 patterns will require these blocks inside every
	boss bot:
	
	EventChangeAttributes
	{
		Default
		{	
		
		}
		Phase1Pattern2
		{
			
		}
		Phase1Pattern2
		{
			
		}
		Phase2Pattern1
		{
			
		}
	}
	
*****************************************************/
::BOSS <-
{
	ref = "BOSS",
	TAG = "orin_boss",
	
	// Intended format:
	// [ mvmbot, lastupdatetime ]
	BOTS = [],
	thinker = null
}

function RunBossLogic(phasecount, patterncount = 1, changetime = 10)
{
	local scope = ::BOSS.thinker.GetScriptScope()
	scope["bossphasecount"] = phasecount
	scope["bosspatterncount"] = patterncount
	scope["bosschangetime"] = changetime
	scope["BossDoRun"] = true
}

function InitBoss()
{
	::TAGS.ClearBots(::BOSS.TAG, ::BOSS.BOTS)
	::BOSS.thinker = SpawnEntityFromTable("logic_relay",{
		targetname = "remorin_bossupdate"
	})
	::BOSS.thinker.ValidateScriptScope()

	local scope = ::BOSS.thinker.GetScriptScope()
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
		
		for( local i = 0; i < ::BOSS.BOTS.len(); i++ )
		{
			local ary = ::BOSS.BOTS[i]
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
						printl(loadout)
						
						scope["bosslastchoice"] = choice
						::BOSS.BOTS[i][1] = Time()
						break;
					}
				}
			}
		}
		
		return 1.0
	}
	
	AddThinkToEnt(::BOSS.thinker, "BossUpdate")
	__CollectGameEventCallbacks(::BOSS)
}

// Collect any boss robot that spawns for later use.
::BOSS.OnGameEvent_post_inventory_application <- function( params )
{
	local player = GetPlayerFromUserID( params.userid )
	if( player.IsFakeClient() )
	{
		EntFireByHandle(player, "RunScriptCode", "::TAGS.RegisterBot(self, ::BOSS.TAG, ::BOSS.BOTS)", 0.1, player, player )
	}
}

// Remove tags from any boss bots that have died.
::BOSS.OnGameEvent_player_death <- function( params )
{
	local player = GetPlayerFromUserID( params.userid )
	::TAGS.UnregisterBot(player, ::BOSS.TAG, ::BOSS.BOTS)
}

// Clear the boss tag from all boss bots.
::BOSS.OnGameEvent_teamplay_round_win <- function( params )
{
	::TAGS.ClearBots(::BOSS.TAG, ::BOSS.BOTS)
	local scope = ::BOSS.thinker.GetScriptScope()
	scope["BossDoRun"] = false
}

// We ought to clean our waste responsibly.
::BOSS.OnGameEvent_teamplay_round_start <- function( params )
{
	local events =
	[
		"post_inventory_application",
		"player_death",
		"teamplay_round_win",
		"teamplay_round_start"
	]

	::ORIN.CheckEvents("BOSS", events)
}

/*****************************************************
	PROJECTILE SHIELD

	Shield Medics aren't taken seriously unless they're
	a squad leader, however during this they do not
	activate their projectile shield unless forced to.
	
	No popfile functions.
	
*****************************************************/
::SHIELD <-
{
	ref = "SHIELD",
	TAG = "orin_shield",
	
	// Intended format:
	// [ mvmbot, lastupdatetime ]
	BOTS = [],
	thinker = null
}

function InitShield()
{
	// TBA
	__CollectGameEventCallbacks(::SHIELD)
}

::SHIELD.OnGameEvent_post_inventory_application <- function( params )
{
	local player = GetPlayerFromUserID( params.userid )
	if( player.IsFakeClient() )
	{
		EntFireByHandle(player, "RunScriptCode", "::TAGS.RegisterBot(self, ::SHIELD.TAG, ::SHIELD.BOTS)", 0.1, player, player )
	}
}

::SHIELD.OnGameEvent_player_death <- function( params )
{
	local player = GetPlayerFromUserID( params.userid )
	::TAGS.UnregisterBot(player, ::SHIELD.TAG, ::SHIELD.BOTS)
}

::SHIELD.OnGameEvent_teamplay_round_win <- function( params )
{
	::TAGS.ClearBots(::SHIELD.TAG, ::SHIELD.BOTS)
}

// We ought to clean our waste responsibly.
::SHIELD.OnGameEvent_teamplay_round_start <- function( params )
{	
	local events =
	[
		"post_inventory_application",
		"player_death",
		"teamplay_round_win",
		"teamplay_round_start"
	]
	
	::ORIN.CheckEvents("SHIELD", events)
}

/*****************************************************
	RED DEFENSE BOTS

	These bots allow for waves to be played without
	opting to the boring way of godmode.
	
	No popfile functions.
	
*****************************************************/
::REDBOTS <- { ref = "REDBOTS" }

function DoRedBots()
{
	// Move out of spawn, you fools
	local redflag = Entities.FindByName(null, "orin_redflag")
	if( !redflag )
	{
		redflag = SpawnEntityFromTable("item_teamflag", {
			targetname = "orin_redflag",
			origin = Vector(3956, 366, 423),
			TeamNum = 2,
			GameType = 1,
			"OnPickup#1": "!self,ForceResetSilent,,0,-1" 
		})
	}

	__CollectGameEventCallbacks(::REDBOTS)
}

::REDBOTS.OnGameEvent_player_spawn <- function( params )
{
	local player = GetPlayerFromUserID( params.userid )
	if( player.GetTeam() == TF_TEAM_PVE_DEFENDERS && player.IsFakeClient() )
	{
		local dosh = NetProps.GetPropInt(::OBJECTIVE, "m_runningTotalWaveStats.nCreditsDropped")
		local classnum = NetProps.GetPropInt(player, "m_PlayerClass")
		player.ValidateScriptScope()
		
		// Good enough for now
		if( classnum == Constants.ETFClass.TF_CLASS_SCOUT )
		{
			EntFire("!activator", "RunScriptCode", "weapon <- NetProps.GetPropEntityArray(self, `m_hMyWeapons`, 0)", 1, player)
			EntFire("!activator", "RunScriptCode", "weapon.AddAttribute(`projectile penetration`, 1, -1)", 2, player)
			EntFire("!activator", "RunScriptCode", "weapon.AddAttribute(`faster reload rate`, 0.6, -1)", 2, player)
			EntFire("!activator", "RunScriptCode", "weapon.AddAttribute(`fire rate bonus`, 0.9, -1)", 2, player)
			
			// not good for tanks
			/* local randnum = RandomInt(0,2)
			if( randnum == 0 )
				player.GenerateAndWearItem("The Buff Banner")
			else if( randnum == 1 )
				player.GenerateAndWearItem("The Concheror")
			else if( randnum == 2 )
				player.GenerateAndWearItem("The Battalion's Backup")
			
			player.AddCustomAttribute("increase buff duration", 1.5, -1)
			player.AddCustomAttribute("deploy time increased", 1.34, -1) */
		}
		else if( classnum == Constants.ETFClass.TF_CLASS_SOLDIER )
		{
			EntFire("!activator", "RunScriptCode", "weapon <- NetProps.GetPropEntityArray(self, `m_hMyWeapons`, 0)", 1, player)
			EntFire("!activator", "RunScriptCode", "weapon.AddAttribute(`rocket specialist`, 1, -1)", 2, player)
			EntFire("!activator", "RunScriptCode", "weapon.AddAttribute(`faster reload rate`, 0.6, -1)", 2, player)
			EntFire("!activator", "RunScriptCode", "weapon.AddAttribute(`fire rate bonus`, 0.9, -1)", 2, player)
			EntFire("!activator", "RunScriptCode", "weapon.AddAttribute(`restore health on kill`, 25, -1)", 2, player)
			player.AddCustomAttribute("move speed bonus", 1.2, -1)
			player.AddCustomAttribute("dmg taken from blast reduced", 0.8, -1)
			player.AddCustomAttribute("dmg taken from bullets reduced", 0.8, -1)
			
			// not good for tanks
			/* local randnum = RandomInt(0,2)
			if( randnum == 0 )
				player.GenerateAndWearItem("The Buff Banner")
			else if( randnum == 1 )
				player.GenerateAndWearItem("The Concheror")
			else if( randnum == 2 )
				player.GenerateAndWearItem("The Battalion's Backup")
			
			player.AddCustomAttribute("increase buff duration", 1.5, -1)
			player.AddCustomAttribute("deploy time increased", 1.34, -1) */
		}
		else if( classnum == Constants.ETFClass.TF_CLASS_HEAVYWEAPONS )
		{
			EntFire("!activator", "RunScriptCode", "weapon <- NetProps.GetPropEntityArray(self, `m_hMyWeapons`, 0)", 1, player)
			EntFire("!activator", "RunScriptCode", "weapon.AddAttribute(`fire rate bonus`, 0.79, -1)", 2, player)
			EntFire("!activator", "RunScriptCode", "weapon.AddAttribute(`ammo regen`, 1, -1)", 2, player)
		}
		else if( classnum == Constants.ETFClass.TF_CLASS_ENGINEER )
		{
			EntFire("!activator", "RunScriptCode", "weapon <- NetProps.GetPropEntityArray(self, `m_hMyWeapons`, 3)", 1, player)
			EntFire("!activator", "RunScriptCode", "weapon.AddAttribute(`engy building health bonus`, 3, -1)", 2, player)
			EntFire("!activator", "RunScriptCode", "weapon.AddAttribute(`metal regen`, 200, -1)", 2, player)
		}
		else if( classnum == Constants.ETFClass.TF_CLASS_MEDIC )
		{
			EntFire("!activator", "RunScriptCode", "weapon <- NetProps.GetPropEntityArray(self, `m_hMyWeapons`, 1)", 1, player)
			EntFire("!activator", "RunScriptCode", "weapon.AddAttribute(`generate rage on heal`, 2, -1)", 2, player)
			EntFire("!activator", "RunScriptCode", "self.AddBotAttribute(Constants.FTFBotAttributeType.PROJECTILE_SHIELD)", 2, player)
			EntFire("!activator", "RunScriptCode", "self.AddBotAttribute(Constants.FTFBotAttributeType.SPAWN_WITH_FULL_CHARGE)", 2, player)
		}
		else
		{
			EntFire("!activator", "RunScriptCode", "weapon <- NetProps.GetPropEntityArray(self, `m_hMyWeapons`, 0)", 1, player)
			EntFire("!activator", "RunScriptCode", "weapon.AddAttribute(`damage bonus`, 1.5, -1)", 2, player)
			EntFire("!activator", "RunScriptCode", "weapon.AddAttribute(`ammo regen`, 1, -1)", 2, player)
		}
		
		// Good enough for now
		if ( dosh > 1200 )
		{
			player.AddCustomAttribute("dmg taken from blast reduced", 0.6, -1)
		}
		else if( dosh > 600 )
		{
			player.AddCustomAttribute("dmg taken from bullets reduced", 0.6, -1)
		}
	}
}

// We ought to clean our waste responsibly.
::REDBOTS.OnGameEvent_teamplay_round_start <- function( params )
{
	local events =
	[
		"teamplay_round_start",
		"player_spawn"
	]

	::ORIN.CheckEvents("REDBOTS", events)
}

// Abracadabra.
Init();