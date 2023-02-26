//Boss RNG Prototype

function BossPhase(ent = null) {
    AddThinkToEnt(ent, "BossPhaseThinkFunction")
}

function BossPhaseThinkFunction() {
    local ent = null
    while( ent = Entities.FindByClassname(ent, "tf_weapon_rocket*") )
    {
        local boss = ent.GetOwner()

        if (boss.IsFakeClient() == false)
            continue

        if (boss.HasBotTag("bot_Boss") == true) {
            local bossRNG = RandomInt(0,2)
			if (BossHalfHealthPhase != 1)
				BossHalfHealthPhase--
			else
				BossHalfHealthPhase = 3

            //100 - 75% health
            if (boss.GetHealth() / boss.GetMaxHealth() > 0.75)
			{
                if (bossRNG == 0)
                    EntFire("point_populator_interface", "ChangeBotAttributes", "Default")
                if (bossRNG == 1)
                    EntFire("point_populator_interface", "ChangeBotAttributes", "BossAttack1")
                if (bossRNG == 2) {
                    EntFire("point_populator_interface", "ChangeBotAttributes", "BossAttack2")
                    boss.AddCondEx(11, 12, boss)
                }
			}
			

            if (boss.GetHealth() / boss.GetMaxHealth() > 0.5 && boss.GetHealth() / boss.GetMaxHealth() < 0.76) {
				if (BossHalfHealthPhase == 3) {
					EntFire("point_populator_interface", "ChangeBotAttributes", "BossHalfHealthAttack1")
				}
				if (BossHalfHealthPhase == 2) {
					EntFire("point_populator_interface", "ChangeBotAttributes", "BossHalfHealthAttack2")
					boss.AddCondEx(11, 12, boss)
				}
				if (BossHalfHealthPhase == 1) {
					EntFire("point_populator_interface", "ChangeBotAttributes", "BossHalfHealthAttack3")
				}
			} 
        }

    }
    //RNG roll every 12 seconds
    return 12
}
