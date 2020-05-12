//////////////////////////////
//Contents: Ladders, Stairs.//
//////////////////////////////

/hook/roundstart/proc/assign_ladder_ids()

	var/list/top_ladders = list()
	var/list/bottom_ladders = list()

	for (var/obj/structure/multiz/ladder/ladder in ladder_list)
		if (ladder.istop)
			if (!top_ladders[ladder.loc])
				top_ladders[ladder.loc] = 0
			++top_ladders[ladder]
			ladder.ladder_id = "[ladder.loc]-[top_ladders[ladder.loc]]"
		else
			if (!bottom_ladders[ladder.loc])
				bottom_ladders[ladder.loc] = 0
			++bottom_ladders[ladder.loc]
			ladder.ladder_id = "[ladder.loc]-[bottom_ladders[ladder.loc]]"

	for (var/obj/structure/multiz/ladder in ladder_list)
		ladder.target = ladder.find_target()
	return TRUE

/obj/structure/multiz
	name = "ladder"
	density = FALSE
	opacity = FALSE
	anchored = TRUE
	icon = 'icons/obj/stairs.dmi'
	var/istop = TRUE
	var/obj/structure/multiz/target

	New()
		. = ..()
		for (var/obj/structure/multiz/M in loc)
			if (M != src)
				spawn(1)
					world.log << "##MAP_ERROR: Multiple [initial(name)] at ([x],[y],[z])"
					qdel(src)
				return .

	CanPass(obj/mover, turf/source, height, airflow)
		return airflow || !density

	proc/find_target()
		return

	initialize()
		find_target()

	attack_ghost(mob/user)
		. = ..()
		user.Move(get_turf(target))

	attackby(obj/item/C, mob/user)
		. = ..()
		attack_hand(user)
		return



////LADDER////

/obj/structure/multiz/ladder
	name = "ladder"
	desc = "A ladder.  You can climb it up and down."
	icon_state = "ladderdown"
	layer = 2.99 // below crates

	var/ladder_id

/obj/structure/multiz/ladder/New()
	..()
	ladder_list += src

/obj/structure/multiz/ladder/Destroy()
	ladder_list -= src
	..()

/obj/structure/multiz/ladder/find_target()
	var/turf/targetTurf = istop ? GetBelow(src) : GetAbove(src)
	return target = locate(/obj/structure/multiz/ladder) in targetTurf

/obj/structure/multiz/ladder/up
	icon_state = "ladderup"
	istop = FALSE

/obj/structure/multiz/ladder/Destroy()
	if (target && istop)
		qdel(target)
	return ..()

/obj/structure/multiz/ladder/attack_hand(var/mob/M)

	if (M.restrained())
		M << "<span class='warning'>You can't use /the [src] while you're restrained.</span>"
		return

	if (!target || !istype(target.loc, /turf))
		M << "<span class='notice'>\The [src] is incomplete and can't be climbed.</span>"
		return

	var/turf/T = target.loc
	if (!istop)
		for (var/atom/movable/AM in T)
			if (AM.density)
				M << "<span class='notice'>\A [AM] is blocking \the [src].</span>"
				return

	M.visible_message(
		"<span class='notice'>\A [M] starts to climb [istop ? "down" : "up"] \a [src].</span>",
		"<span class='notice'>You start to climb [istop ? "down" : "up"] \the [src].</span>",
		"You hear the grunting and clanging of a metal ladder being used."
	)

	T.visible_message(
		"<span class='warning'>Someone starts to climb [istop ? "down" : "up"] \a [src].</span>",
		"You hear the grunting and clanging of a metal ladder being used."
	)

	if (do_after(M, 10, src))
		playsound(loc, 'sound/effects/ladder.ogg', 50, TRUE, -1)

		// pulling/grabbing people with you
		var/atom/movable/was_pulling = null
		var/grabbing = FALSE

		if (M.pulling)
			was_pulling = M.pulling
			M.stop_pulling(was_pulling)
		else
			for (var/obj/item/weapon/grab/G in M.contents)
				if (G.affecting)
					was_pulling = G.affecting
					grabbing = TRUE
					break

		if (was_pulling)
			var/turf/move_pulling = get_step(T, M.dir)
			if (move_pulling.density)
				move_pulling = get_step(T, NORTH)
			if (move_pulling.density)
				move_pulling = get_step(T, SOUTH)
			if (move_pulling.density)
				move_pulling = get_step(T, EAST)
			if (move_pulling.density)
				move_pulling = get_step(T, WEST)
			if (move_pulling.density)
				move_pulling = get_step(T, NORTHEAST)
			if (move_pulling.density)
				move_pulling = get_step(T, NORTHWEST)
			if (move_pulling.density)
				move_pulling = get_step(T, SOUTHEAST)
			if (move_pulling.density)
				move_pulling = get_step(T, SOUTHWEST)

			was_pulling.Move(move_pulling)
			M.Move(T)

			if (was_pulling && !grabbing)
				M.start_pulling(was_pulling)
		else
			M.Move(T)
		M.visible_message(
			"<span class='notice'>\A [M] climbs [istop ? "down" : "up"] \a [src].</span>",
			"<span class='notice'>You climb [istop ? "down" : "up"] \the [src].</span>",
			"You hear the grunting and clanging of a metal ladder being used."
		)

/mob/living/carbon/human/var/laddervision = null

/obj/structure/multiz/ladder/MouseDrop_T(var/mob/living/carbon/human/user as mob)
	if (!user || !istype(user))
		return
	if (user.laddervision == src)
		return
	if (!target)
		return
	if (user.laddervision)
		user.update_laddervision(target) // stop looking up/down
		return

	visible_message("<span class = 'notice'>[user] starts to look [target.laddervision_direction()] \the [src].</span>")
	if (do_after(user, 12, src))
		user.update_laddervision(target)
		visible_message("<span class = 'notice'>[user] looks [user.laddervision_direction()] \the [src].</span>")

/mob/living/carbon/human/proc/update_laddervision(var/obj/structure/multiz/ladder/ladder)
	if (ladder && istype(ladder))
		client.perspective = EYE_PERSPECTIVE
		laddervision = ladder
		client.eye = laddervision
	else if (!ladder && laddervision)
		client.perspective = MOB_PERSPECTIVE
		client.eye = src
		laddervision = null

/obj/structure/multiz/proc/laddervision_direction()
	if (istop)
		return "up"
	else
		return "down"

/mob/living/carbon/human/proc/laddervision_direction()
	if (!laddervision)
		return ""
	var/obj/structure/multiz/ladder = laddervision
	if (ladder.istop)
		return "up"
	return "down"

/obj/structure/multiz/ladder/autotop/New()
	var/turf/T = GetBelow(src)
	var/obj/structure/multiz/ladder/newthing = new /obj/structure/multiz/ladder/up
	newthing.loc = locate(T)
	if(!newthing.loc)
		qdel(src)
		world << "span class=danger'ERROR: Ladder led to null location.</span>"
	. = ..()

/obj/structure/multiz/stairs
	name = "Stairs"
	icon_state = "rampup"
	layer = 2.4

/obj/structure/multiz/stairs_wood
	name = "Wood Stairs"
	icon_state = "wood2_stairs"
	layer = 2.4


/obj/structure/multiz/stairs/enter
	icon_state = "ramptop"

/obj/structure/multiz/stairs/enter/bottom
	icon_state = "rampbottom"
	istop = FALSE

/obj/structure/multiz/stairs/active
	density = TRUE

/obj/structure/multiz/stairs/active/find_target()
	var/turf/targetTurf = istop ? GetBelow(src) : GetAbove(src)
	target = locate(/obj/structure/multiz/stairs/enter) in targetTurf

/obj/structure/multiz/stairs/active/Bumped(var/atom/movable/M)
	if (isnull(M))
		return

	if (ismob(M) && usr.client)
		usr.client.moving = TRUE
		usr.Move(get_turf(target))
		usr.client.moving = FALSE
	else
		M.Move(get_turf(target))


/obj/structure/stairs/active/attack_hand(mob/user)
	. = ..()
	if (Adjacent(user))
		Bumped(user)

/obj/structure/multiz/stairs/active/bottom
	icon_state = "rampdark"
	istop = FALSE

/obj/structure/multiz/stairs/active/bottom/Bumped(var/atom/movable/M)
	//If on bottom, only let them go up stairs if they've moved to the entry tile first.
	if (!locate(/obj/structure/multiz/stairs/enter) in M.loc)
		return
	return ..()
