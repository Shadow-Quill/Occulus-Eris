var/global/list/limb_icon_cache = list()

/obj/item/organ/external/set_dir()
	return

/obj/item/organ/external/proc/compile_icon()
	overlays.Cut()
	 // This is a kludge, only one icon has more than one generation of children though.
	for(var/obj/item/organ/external/organ in contents)
		if(organ.children && organ.children.len)
			for(var/obj/item/organ/external/child in organ.children)
				overlays += child.mob_icon
		overlays += organ.mob_icon

/obj/item/organ/external/proc/sync_colour_to_human(var/mob/living/carbon/human/human)
	skin_tone = null
	s_col = null
	h_col = list(human.r_hair, human.g_hair, human.b_hair)
	if(BP_IS_ROBOTIC(src))
		return
	if(species && human.species && species.name != human.species.name)
		return
	if(!isnull(human.s_tone) && (human.species.appearance_flags & HAS_SKIN_TONE))
		skin_tone = human.s_tone
	if(human.species.appearance_flags & HAS_SKIN_COLOR)
		s_col = list(human.r_skin, human.g_skin, human.b_skin)

/obj/item/organ/external/proc/get_cache_key()
	var/part_key = ""

	if(!appearance_test.get_species_sprite)
		part_key += "forced"
	else
		if(BP_IS_ROBOTIC(src))
			part_key += "ROBOTIC"
		else if(status & ORGAN_MUTATED)
			part_key += "Mutated"
		else if(status & ORGAN_DEAD)
			part_key += "Dead"
		else
			part_key += "Normal"
		part_key += "[species.race_key]"

	if(!appearance_test.colorize_organ)
		part_key += "no_color"

	part_key += "[owner && owner.gender == FEMALE]"
	part_key += "[skin_tone]"
	part_key += rgb(s_col[1], s_col[2], s_col[3], species.body_alpha)
	part_key += model

	if(!appearance_test.special_update)
		for(var/obj/item/organ/internal/eyes/I in internal_organs)
			part_key += I.get_cache_key()

///// OCCULUS EDIT START - delete the laggy old markings system, this is the actual icon caching bit
	for(var/M in markings)
		part_key += "[M][markings[M]["color"]]"
///// OCCULUS EDIT END /////

	return part_key

/obj/item/organ/external/head/sync_colour_to_human(var/mob/living/carbon/human/human)
	..()
	for(var/obj/item/organ/internal/eyes/eyes in owner.organ_list_by_process(OP_EYES))
		eyes.update_colour()

/obj/item/organ/external/head/removed_mob()
	update_icon(1)
	..()

/obj/item/organ/external/head/on_update_icon()

	..()
	if(!appearance_test.special_update)
		return mob_icon

	overlays.Cut()
	if(!owner || !owner.species)
		return

	if(!species)
		species = owner.species

	if(owner.species.has_process[OP_EYES] && species.appearance_flags & HAS_EYE_COLOR)
		for(var/obj/item/organ/internal/eyes/eyes in owner.organ_list_by_process(OP_EYES))
			mob_icon.Blend(eyes.get_icon(), ICON_OVERLAY)

	if(owner.lip_style && (species && (species.appearance_flags & HAS_LIPS)))
		var/icon/lip_icon = new/icon('icons/mob/human_face.dmi', "lips[owner.lip_style]")
		mob_icon.Blend(lip_icon, ICON_OVERLAY)

	if(!BP_IS_ROBOTIC(src))
		if(owner.f_style)
			var/datum/sprite_accessory/facial_hair_style = GLOB.facial_hair_styles_list[owner.f_style]
			if(facial_hair_style && facial_hair_style.species_allowed && (species.get_bodytype() in facial_hair_style.species_allowed))
				var/icon/facial = new/icon("icon" = facial_hair_style.icon, "icon_state" = "[facial_hair_style.icon_state]_s")
				if(facial_hair_style.do_colouration)
					facial.Blend(rgb(owner.r_facial, owner.g_facial, owner.b_facial, owner.species.hair_alpha), ICON_ADD) // OCCULUS EDIT - hair alpha for slimes
				overlays |= facial

		if(owner.h_style && !(owner.head && (owner.head.flags_inv & BLOCKHEADHAIR)))
			var/datum/sprite_accessory/hair_style = GLOB.hair_styles_list[owner.h_style]
			if(hair_style && (species.get_bodytype() in hair_style.species_allowed))
				var/icon/hair = new/icon(hair_style.icon, hair_style.icon_state)
				if(hair_style.do_colouration)
					hair.Blend(rgb(owner.r_hair, owner.g_hair, owner.b_hair, owner.species.hair_alpha), ICON_MULTIPLY)	//Eclipse edit. // OCCULUS EDIT - hair alpha for slimes
			// OCCULUS EDIT START - Hair Color Gradients
					for(var/M in markings)
						var/datum/sprite_accessory/marking/mark_style = markings[M]["datum"]
						if(mark_style.draw_target == 1)
							var/icon/mark_s = new/icon(mark_style.icon, mark_style.icon_state)
							mark_s.Blend(hair, ICON_AND)
							mark_s.Blend(markings[M]["color"], mark_style.color_blend_mode)
							hair.Blend(mark_s, ICON_OVERLAY)
			// OCCULUS EDIT END - Hair Color Gradients
				overlays |= hair

///// OCCULUS EDIT START - delete the laggy old markings system
	for(var/M in markings)
		var/datum/sprite_accessory/marking/mark_style = markings[M]["datum"]
		if(!mark_style.draw_target)
			var/icon/mark_s = new/icon("icon" = mark_style.icon, "icon_state" = "[mark_style.icon_state]-[organ_tag]")
			mark_s.Blend(markings[M]["color"], mark_style.color_blend_mode)
			add_overlay(mark_s) //So when it's not on your body, it has icons
			mob_icon.Blend(mark_s, ICON_OVERLAY) //So when it's on your body, it has icons
		//icon_cache_key += "[M][markings[M]["color"]]"	//This is implemented in get_cache_keys() instead
///// OCCULUS EDIT END /////

	return mob_icon

/obj/item/organ/external/on_update_icon(regenerate = 0)
	var/gender = "_m"
	gender = owner.gender == FEMALE ? "_f" : "_m"

	overlays.Cut()	// OCCULUS EDIT - Make sure we're not stacking up redundant overlays

	if(appearance_test.simple_setup)
		icon_state = "[organ_tag][gender]"
	else
		icon_state = "[organ_tag][gender][is_stump()?"_s":""]"

	if(!species && iscarbon(owner))
		species = owner.species

	if(!appearance_test.get_species_sprite)
		icon = 'icons/mob/human_races/r_human.dmi'
	else
		if(src.force_icon)
			icon = src.force_icon
		else if(!species)
			icon = 'icons/mob/human_races/r_human.dmi'
		else if(BP_IS_ROBOTIC(src))
			icon = 'icons/mob/human_races/cyberlimbs/generic.dmi'
		else if(status & ORGAN_MUTATED)
			icon = species.deform
		else
			icon = species.icobase

	mob_icon = new/icon(icon, icon_state)

	if(appearance_test.colorize_organ)
		if(status & ORGAN_DEAD)
			mob_icon.ColorTone(rgb(10,50,0))
			mob_icon.SetIntensity(0.7)
		if(skin_tone)
			if(skin_tone >= 0)
				mob_icon.Blend(rgb(skin_tone, skin_tone, skin_tone), ICON_ADD)
			else
				mob_icon.Blend(rgb(-skin_tone,  -skin_tone,  -skin_tone), ICON_SUBTRACT)
		else
			if(s_col)
				mob_icon.Blend(rgb(s_col[1], s_col[2], s_col[3], species.body_alpha), ICON_MULTIPLY) // OCCULUS EDIT - body alpha for slimes

	///// OCCULUS EDIT START - Delete the laggy body marking system /////
	if(!istype(src,/obj/item/organ/external/head))
		for(var/M in markings)
			var/datum/sprite_accessory/marking/mark_style = markings[M]["datum"]
			var/icon/mark_s = new/icon("icon" = mark_style.icon, "icon_state" = "[mark_style.icon_state]-[organ_tag]")
			mark_s.Blend(markings[M]["color"], mark_style.color_blend_mode)
			add_overlay(mark_s) //So when it's not on your body, it has icons
			mob_icon.Blend(mark_s, ICON_OVERLAY) //So when it's on your body, it has icons
			//icon_cache_key += "[M][markings[M]["color"]]"	//This is implemented in get_cache_keys() instead
	///// OCCULUS EDIT END /////

	dir = EAST
	icon = mob_icon

/obj/item/organ/external/proc/get_icon()
	update_icon()
	return mob_icon
