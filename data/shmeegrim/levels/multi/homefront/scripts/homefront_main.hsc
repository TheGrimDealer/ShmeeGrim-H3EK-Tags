(script startup homefront_main	
    (sleep 30)
	(mp_wake_script PhantomAnimControl)
)

(script continuous guardian_main
	(add_recycling_volume garbage 30 30)
	(sleep 900)
)

(script dormant PhantomAnimControl
	(sleep_until
		(begin
			(print "new start")
			(sleep (random_range 1200 1500))
			(PhantomAnimSelect (random_range 1 2))
			(sleep (* 360 30))
		0)
	)
)

(script static void (PhantomAnimSelect (short anim_num))
	
	(object_set_function_variable Phantom_01 scripted_object_function_c 1 1)
	(object_set_function_variable Phantom_01 scripted_object_function_a 1 1)
	(object_set_function_variable Phantom_01 scripted_object_function_b 1 1)
	
	
	(if (= anim_num 1)
		(begin
			(object_create Phantom_01)
			(scenery_animation_start Phantom_01 cone_collective\objects\levels\multi\homefront\homefront_phantom\homefront_phantom "homefront_phantom_anim_01")
			(object_set_custom_animation_speed Phantom_01 0.35)
			(sleep 190)
			(object_set_function_variable Phantom_01 scripted_object_function_d 1 1)
			(sleep_until
				(= (scenery_get_animation_time Phantom_01) 0)
			)
		)
	)
	
		(if (= anim_num 2)
		(begin
			(object_create Phantom_01)
			(scenery_animation_start Phantom_01 cone_collective\objects\levels\multi\homefront\homefront_phantom\homefront_phantom "homefront_phantom_anim_01")
			(object_set_custom_animation_speed Phantom_01 0.35)
			(sleep 190)
			(object_set_function_variable Phantom_01 scripted_object_function_d 1 1)
			(sleep_until
				(= (scenery_get_animation_time Phantom_01) 0)
			)
		)
	)
	
	(object_set_function_variable Phantom_01 scripted_object_function_c 0 1)
	(object_set_function_variable Phantom_01 scripted_object_function_a 0 1)
	(object_set_function_variable Phantom_01 scripted_object_function_b 0 1)
	(object_set_function_variable Phantom_01 scripted_object_function_d 0 1)
	(object_destroy Phantom_01)
)

;///////////////////////
;//// PODIUM SCRIPT ////
;///////////////////////



