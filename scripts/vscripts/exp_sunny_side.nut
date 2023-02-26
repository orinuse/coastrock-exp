// For Remilia and Orin's Sunny-Side Up
// ====================================

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
	
local GAMERULES_ENT = Entities.FindByClassname(null, "tf_gamerules")

function Init()
{
	local EngyHints =
	[
		// Each entry is an 2D array with 2 more arrays inside
		// 1st among the two is a sentry hint, and the other a nest hint
		[[Vector(566, -473, 64), QAngle(0,48,0)], [Vector(372, -630, 64), QAngle(16,36,0)]],
	]
	
	for( local i = 0; i < EngyHints.len(); i++ )
	{
		SpawnEntityFromTable("bot_hint_sentrygun", {
			targetname = "remorin_hint_engy"+i,
			origin = EngyHints[i][0][0],
			angles = EngyHints[i][0][1]
		})
		SpawnEntityFromTable("bot_hint_engineer_nest", {
			targetname = "remorin_hint_engy"+i,
			origin = EngyHints[i][1][0],
			angles = EngyHints[i][1][1]
		})
	}
}

function StartWaveBreak(duration, music, pathrelay = null)
{
	if ( !music )
		music = "music/mvm_start_mid_wave.wav"

	// PATHS
	if ( pathrelay == null )
		pathrelay = "bombpath_choose_relay"
	else if ( pathrelay == "Left" )
		pathrelay = "bombpath_left"
	else if ( pathrelay == "Right" )
		pathrelay = "bombpath_right"
	
	// LOGIC
	EntFire("bombpath_arrows_clear_relay", "Trigger")
	EntFire("item_teamflag", "ForceReset")
	EntFire("upgrade_door_open_relay", "Trigger")
	EntFire("point_populator_interface", "PauseBotSpawning")
	EntFire( "bombpath_arrows_clear_relay", "Trigger", null, duration)
	EntFire("upgrade_door_close_relay", "Trigger", null, duration)
	EntFire("point_populator_interface", "UnpauseBotSpawning", null, duration)

	local size = EndVOs.len() - 1
	local choice = EndVOs[RandomInt(0,size)]
	EntFireByHandle(GAMERULES_ENT, "PlayVORed", choice, 0, GAMERULES_ENT, GAMERULES_ENT )
	EntFireByHandle(GAMERULES_ENT, "PlayVORed", "Announcer.MVM_Get_To_Upgrade", 5, GAMERULES_ENT, GAMERULES_ENT )
	EntFire( pathrelay, "Trigger", 10)
	
	// SOUND
	if( duration >= 35 )
	{
		local delta = (duration - 20)
		EntFireByHandle(GAMERULES_ENT, "PlayVORed", COUNTDOWN_20s, delta, GAMERULES_ENT, GAMERULES_ENT )
	}
	if( duration >= 25 )
	{
		local delta = (duration - 10)
		EntFireByHandle(GAMERULES_ENT, "PlayVORed", COUNTDOWN_10s, delta, GAMERULES_ENT, GAMERULES_ENT )
	}
	if( duration >= 15 )
	{
		local delta = (duration - 5)		
		local size = (StartVOs.len() - 1)
		local choice = RandomInt(0,size)
		local rVO = StartVOs[choice][0]
		local rFixup = StartVOs[choice][1]

		EntFireByHandle(GAMERULES_ENT, "PlayVORed", rVO, delta + rFixup, GAMERULES_ENT, GAMERULES_ENT )
		EntFireByHandle(GAMERULES_ENT, "PlayVORed", music, delta + rFixup, GAMERULES_ENT, GAMERULES_ENT )
	}
}

Init()