/datum/holotool_mode
	var/name = ""
	var/sound
	var/behavior
	var/sharpness
	var/speed = 1.2 // 20% worse than regular tools by default

/datum/holotool_mode/proc/can_be_used(obj/item/holotool/H)
	return TRUE

/datum/holotool_mode/proc/on_set(obj/item/holotool/H)
	H.usesound = sound ? sound : 'sound/items/pshoom.ogg'
	H.toolspeed = speed ? speed : 1
	H.tool_behaviour = behavior ? behavior : null
	H.sharpness = sharpness ? sharpness : NONE

/datum/holotool_mode/proc/on_unset(obj/item/holotool/H)
	H.usesound = initial(H.usesound)
	H.toolspeed = initial(H.toolspeed)
	H.tool_behaviour = initial(H.tool_behaviour)
	H.sharpness = initial(H.sharpness)

////////////////////////////////////////////////

// NAME USED FOR OVERLAYS, MAKE SURE IT MATCHES
/datum/holotool_mode/off
	name = "off"
	sound = 'sound/items/holotool.ogg'

/datum/holotool_mode/screwdriver
	name = "holo-screwdriver"
	sound = 'sound/items/holotool.ogg'
	behavior = TOOL_SCREWDRIVER
	sharpness = SHARP_POINTY

/datum/holotool_mode/crowbar
	name = "holo-crowbar"
	sound = 'sound/items/holotool.ogg'
	behavior = TOOL_CROWBAR

/datum/holotool_mode/multitool
	name = "holo-multitool"
	sound = 'sound/items/holotool.ogg'
	behavior = TOOL_MULTITOOL

/datum/holotool_mode/wrench
	name = "holo-wrench"
	sound = 'sound/items/holotool.ogg'
	behavior = TOOL_WRENCH

/datum/holotool_mode/wirecutters
	name = "holo-wirecutters"
	sound = 'sound/items/holotool.ogg'
	behavior = TOOL_WIRECUTTER

/datum/holotool_mode/welder
	name = "holo-welder"
	sound = list('sound/items/welder.ogg', 'sound/items/welder2.ogg')//so it actually gives the expected feedback from welding
	behavior = TOOL_WELDER

/datum/holotool_mode/welder/on_set(obj/item/holotool/H)
	..()
	H.AddElement(/datum/element/tool_flash, H.light_outer_range)

/datum/holotool_mode/welder/on_unset(obj/item/holotool/H)
	..()
	H.RemoveElement(/datum/element/tool_flash, H.light_outer_range)

////////////////////////////////////////////////

/datum/holotool_mode/knife
	name = "holo-knife"
	sound = 'sound/weapons/blade1.ogg'
	sharpness = SHARP_EDGED

/datum/holotool_mode/knife/can_be_used(obj/item/holotool/H)
	return (H.obj_flags & EMAGGED)

/datum/holotool_mode/knife/on_set(obj/item/holotool/H)
	..()
	H.force = 17
	H.attack_verb_continuous = list("sliced", "torn", "cut")
	H.armour_penetration = 45
	H.embedding = list("embed_chance" = 40, "embedded_fall_chance" = 0, "embedded_pain_multiplier" = 5)
	H.hitsound = 'sound/weapons/blade1.ogg'

/datum/holotool_mode/knife/on_unset(obj/item/holotool/H)
	..()
	H.force = initial(H.force)
	H.attack_verb_continuous = initial(H.attack_verb_continuous)
	H.armour_penetration = initial(H.armour_penetration)
	H.embedding = initial(H.embedding)
	H.hitsound = initial(H.hitsound)
