/mob/living/carbon/human/Life()
	. = ..()

	fire_alert = 0 //Reset this here, because both breathe() and handle_environment() have a chance to set it.


	//update the current life tick, can be used to e.g. only do something every 4 ticks
	life_tick++

	if(notransform)
		return

	if(!HAS_TRAIT(src, TRAIT_STASIS))
		if(stat != DEAD)

			// Increase germ_level regularly
			if(germ_level < GERM_LEVEL_AMBIENT && prob(30))	//if you're just standing there, you shouldn't get more germs beyond an ambient level
				germ_level++

			handle_breath()
			//blood
			handle_blood()

			if(stat == CONSCIOUS && getToxLoss() >= 45 && nutrition > 20)
				vomit()

			handle_shock()

			handle_pain()

			//In case we want them to do something unique every life cycle, like twitch or moan, or whatever.
			species.handle_unique_behavior(src)

		else //Dead
			dead_ticks ++
			if(dead_ticks > TIME_BEFORE_DNR)
				set_undefibbable()
			else
				med_hud_set_status()

	stabilize_body_temperature() //Body temperature adjusts itself (self-regulation) (even when dead)

	//Handle temperature/pressure differences between body and environment
	handle_environment() //Optimized a good bit.


/mob/living/carbon/human/proc/set_undefibbable()
	if(issynth(src)) //synths do not dnr.
		return
	ADD_TRAIT(src, TRAIT_UNDEFIBBABLE , TRAIT_UNDEFIBBABLE)
	SEND_SIGNAL(src, COMSIG_HUMAN_SET_UNDEFIBBABLE)
	SSmobs.stop_processing(src) //Last round of processing.

	if((SSticker.mode?.round_type_flags & MODE_TWO_HUMAN_FACTIONS) && job?.job_cost)
		job.free_job_positions(1)
	if(hud_list)
		med_hud_set_status()

/mob/living/carbon/human/proc/handle_breath()
	if(species.species_flags & NO_BREATHE)
		return

	if(pulledby?.grab_state >= GRAB_KILL)
		Losebreath(1)
		adjustOxyLoss(4)
	else if(losebreath > 10)
		set_Losebreath(10) //Any single hit is functionally capped - to keep someone suffocating, you need continued losebreath applications.
	else if(losebreath > 0)
		adjust_Losebreath(-1) //Since this happens before checking to take/heal oxyloss, a losebreath of 1 or less won't do anything.

	if(health < get_crit_threshold() || losebreath)
		if(HAS_TRAIT(src, TRAIT_IGNORE_SUFFOCATION)) //Prevent losing health from asphyxiation, but natural recovery can still happen.
			return
		adjustOxyLoss(CARBON_CRIT_MAX_OXYLOSS, TRUE)
		if(!oxygen_alert)
			emote("gasp")
			oxygen_alert = TRUE
	else
		adjustOxyLoss(CARBON_RECOVERY_OXYLOSS, TRUE)
		if(oxygen_alert)
			to_chat(src, span_notice("Fresh air fills your lungs; you can breath again!"))
			oxygen_alert = FALSE
