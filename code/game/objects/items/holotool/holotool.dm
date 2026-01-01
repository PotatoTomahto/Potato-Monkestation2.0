/obj/item/holotool
	name = "experimental holotool"
	desc = "A highly experimental holographic tool projector. Less efficient than its physical counterparts."
	icon = 'icons/obj/holotool.dmi'
	icon_state = "holotool"
	inhand_icon_state = "holotool"
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	usesound = 'sound/items/pshoom.ogg'
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	actions_types = list(/datum/action/item_action/change_tool, /datum/action/item_action/change_ht_color)
	action_slots = ITEM_SLOT_HANDS | ITEM_SLOT_BELT
	resistance_flags = FIRE_PROOF | ACID_PROOF
	light_system = OVERLAY_LIGHT
	light_outer_range = 3
	light_on = FALSE

	/// The current mode
	var/datum/holotool_mode/current_tool
	var/current_light_color = "#48D1CC" //mediumturquoise
	/// Buffer used by the multitool mode
	var/datum/buffer
	/// Component buffer
	var/datum/comp_buffer

/obj/item/holotool/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob, ITEM_SLOT_HANDS|ITEM_SLOT_BELT)

/obj/item/holotool/examine(mob/user)
	. = ..()
	. += span_notice("It is currently set to the [current_tool ? current_tool.name : "off"] mode.")
	if(tool_behaviour == TOOL_MULTITOOL)
		. += span_notice("Its buffer [buffer ? "contains [buffer]." : "is empty."]")
	. += span_info("Attack self to select tool modes.")

// Welding tool repair is currently hardcoded and not based on tool behavior
/obj/item/holotool/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!ishuman(interacting_with) || user.istate & ISTATE_HARM)
		return NONE

	if(tool_behaviour == TOOL_WELDER)
		return try_heal_loop(interacting_with, user)

	return NONE

/obj/item/holotool/proc/try_heal_loop(atom/interacting_with, mob/living/user, repeating = FALSE)
	var/mob/living/carbon/human/attacked_humanoid = interacting_with
	var/obj/item/bodypart/affecting = attacked_humanoid.get_bodypart(check_zone(user.zone_selected))
	if(isnull(affecting) || !IS_ROBOTIC_LIMB(affecting))
		return NONE

	if (!affecting.brute_dam)
		balloon_alert(user, "limb not damaged")
		return ITEM_INTERACT_BLOCKING

	user.visible_message(span_notice("[user] starts to fix some of the dents on [attacked_humanoid == user ? user.p_their() : "[attacked_humanoid]'s"] [affecting.name]."),
		span_notice("You start fixing some of the dents on [attacked_humanoid == user ? "your" : "[attacked_humanoid]'s"] [affecting.name]."))
	var/use_delay = repeating ? 1 SECONDS : 0
	if(user == attacked_humanoid)
		use_delay = 5 SECONDS

	if(!use_tool(attacked_humanoid, user, use_delay, volume=50, amount=1))
		return ITEM_INTERACT_BLOCKING

	if(!item_heal_robotic(attacked_humanoid, user, brute_heal = 15, burn_heal = 0))
		return ITEM_INTERACT_BLOCKING

	INVOKE_ASYNC(src, PROC_REF(try_heal_loop), interacting_with, user, TRUE)
	return ITEM_INTERACT_SUCCESS

/obj/item/holotool/use(used)
	SHOULD_CALL_PARENT(FALSE)
	return TRUE //it just always works, capiche!?

/obj/item/holotool/tool_use_check(mob/living/user, amount)
	return TRUE	//always has enough "fuel"

/obj/item/holotool/ui_action_click(mob/user, datum/action/action)
	if(istype(action, /datum/action/item_action/change_tool))
		return ..()
	else if(istype(action, /datum/action/item_action/change_ht_color))
		var/C = input(user, "Select Color", "Select Color", "#48D1CC") as null|color
		if(!C || QDELETED(src) || !user?.Adjacent(src))
			return
		current_light_color = C
		set_light_color(current_light_color)
		update_appearance(UPDATE_ICON)

/obj/item/holotool/proc/switch_tool(mob/user, datum/holotool_mode/mode)
	if(!istype(mode))
		return
	current_tool?.on_unset(src)
	current_tool = mode
	current_tool.on_set(src)
	playsound(loc, 'sound/items/holotool.ogg', 100, 1, -1)
	update_appearance(UPDATE_ICON)

/obj/item/holotool/proc/build_listing()
	var/list/possible_modes = list()
	for(var/A in subtypesof(/datum/holotool_mode))
		var/datum/holotool_mode/M = new A
		if(M.can_be_used(src))
			var/image/holotool_img = image(icon = icon, icon_state = icon_state)
			var/image/tool_img = image(icon = icon, icon_state = M.name)
			tool_img.color = current_light_color
			holotool_img.overlays += tool_img
			possible_modes[M] = holotool_img
		else
			qdel(M)
	return possible_modes

// Handles color overlay of current holotool mode
/obj/item/holotool/update_overlays()
	. = ..()
	if(current_tool)
		var/mutable_appearance/holo_item = mutable_appearance(icon, current_tool.name)
		holo_item.color = current_light_color
		. += holo_item

/obj/item/holotool/update_icon_state()
	if(current_tool)
		inhand_icon_state = current_tool.name
	else
		inhand_icon_state = initial(inhand_icon_state)
	return ..()

/obj/item/holotool/update_icon(updates=ALL)
	. = ..()
	if(current_tool && !istype(current_tool, /datum/holotool_mode/off))
		set_light_on(TRUE)
	else
		set_light_on(FALSE)

	for(var/datum/action/A as anything in actions)
		A.build_all_button_icons()

/obj/item/holotool/proc/check_menu(mob/living/user)
	if(!istype(user) || user.incapacitated())
		return FALSE
	return TRUE

/obj/item/holotool/attack_self(mob/user)
	var/list/possible_choices = build_listing()
	var/chosen = show_radial_menu(user, src, possible_choices, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE)
	if(!chosen)
		return
	switch_tool(user, chosen)

/obj/item/holotool/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(obj_flags & EMAGGED)
		return FALSE
	to_chat(user, span_danger("ZZT- ILLEGAL BLUEPRINT UNLOCKED- CONTACT !#$@^%$# NANOTRASEN SUPPORT-@*%$^%!"))
	do_sparks(5, 0, src)
	obj_flags |= EMAGGED
	return TRUE

/*
 * Sets the multitool internal object buffer
 *
 * Arguments:
 * * buffer - the new object to assign to the multitool's buffer
 */
/obj/item/holotool/proc/set_buffer(datum/buffer)
	if(src.buffer)
		UnregisterSignal(src.buffer, COMSIG_QDELETING)
	src.buffer = buffer
	if(!QDELETED(buffer))
		RegisterSignal(buffer, COMSIG_QDELETING, PROC_REF(on_buffer_del))

/**
 * Called when the buffer's stored object is deleted
 *
 * This proc does not clear the buffer of the multitool, it is here to
 * handle the deletion of the object the buffer references
 */
/obj/item/holotool/proc/on_buffer_del(datum/source)
	SIGNAL_HANDLER
	buffer = null

/**
 * Sets the holotool component buffer
 *
 * Arguments:
 * * buffer - the new object to assign to the holotool's component buffer
 */
/obj/item/holotool/proc/set_comp_buffer(datum/comp_buffer)
	if(src.comp_buffer)
		UnregisterSignal(src.comp_buffer, COMSIG_QDELETING)
	src.comp_buffer = comp_buffer
	if(!QDELETED(comp_buffer))
		RegisterSignal(comp_buffer, COMSIG_QDELETING, PROC_REF(on_comp_buffer_del))

/**
 * Called when the buffer's stored component buffer is deleted
 *
 * This proc does not clear the component buffer of the holotool, it is here to
 * handle the deletion of the object the buffer references
 */
/obj/item/holotool/proc/on_comp_buffer_del(datum/source)
	SIGNAL_HANDLER
	comp_buffer = null
