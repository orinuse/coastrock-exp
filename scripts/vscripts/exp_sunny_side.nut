// For Remilia and Orin's Sunny-Side Up
// ====================================

const GAMERULES = "tf_gamerules"
const COUNTDOWN_20s = "vo/announcer_begins_20sec.mp3"
const COUNTDOWN_10s = "vo/announcer_begins_10sec.mp3"

local StartSounds =
[
	"vo/mvm_general_wav_start02.mp3"
]

function Init()
{
	local EngyHints =
	[
		// Each entry is aN 2D array with 2 more arrays inside
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
		pathrelay = "music/mvm_start_mid_wave.wav"

	if ( !pathrelay )
		pathrelay = "bombpath_choose_relay"
	
	// LOGIC
	EntFire("bombpath_arrows_clear_relay", "Trigger")
	EntFire("item_teamflag", "ForceReset")
	EntFire("point_populator_interface", "PauseBotSpawning")
	EntFire(pathrelay, "Trigger", duration)
	EntFire("upgrade_door_close_relay", "Trigger", duration)
	EntFire("point_populator_interface", "UnpauseBotSpawning", duration)
	
	// SOUND
	if( duration >= 30 )
	{
		local delta = (duration - 20)
		EntFire(GAMERULES, "PlayVORed", COUNTDOWN_20s, duration - delta )
	}
	if( duration >= 20 )
	{
		local delta = (duration - 10)
		EntFire(GAMERULES, "PlayVORed", COUNTDOWN_10s, duration - delta )
	}
	if( duration >= 10 )
	{
		local size = StartSounds.len() - 1
		local delta = (duration - 5)
		EntFire(GAMERULES, "PlayVORed", StartSounds[RandomInt(0,size)], duration - delta )
		EntFire(GAMERULES, "PlayVORed", pathrelay, duration - delta )
	}
}

Init()