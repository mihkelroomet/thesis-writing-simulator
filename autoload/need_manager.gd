extends Node

signal need_satisfaction_changed(need : Need, new_value : float)

const EffectData = preload("res://data/effect_data.gd")

enum Need {AUTONOMY, COMPETENCE, RELATEDNESS, NUTRITION, PA, SLEEP}

const NEED_NAMES : Array = ["Autonomy", "Competence", "Relatedness", "Nutrition", "Physical Activity", "Sleep"]
const NEED_NAMES_ABBR : Array = ["AUT", "COM", "REL", "NUT", "PHY", "SLE"]

## Current satisfaction of needs
var need_stats : Dictionary = {
	Need.AUTONOMY : 0.8,
	Need.COMPETENCE : 0.8,
	Need.RELATEDNESS : 0.8,
	Need.NUTRITION : 0.8,
	Need.PA : 0.8,
	Need.SLEEP : 0.8
}

func _ready():
	need_satisfaction_changed.connect(Events._on_need_satisfaction_changed)

func _process(delta):
	if GameManager.time_is_advancing:
		var game_hours_elapsed = delta * GameManager.game_speed / 3600
		update_needs(game_hours_elapsed)

func update_needs(game_hours_elapsed):
	for need in Need.values():
		update_need(need, game_hours_elapsed)

func update_need(need, game_hours_elapsed):
	# The effect the current activity has on the need
	var effect_data : EffectData = ActivityManager.get_current_activity_data().effects[need]
	var current_need_satisfaction = need_stats[need]
	
	# The value the need change calculation is based on
	var base_amount_to_calc_change : float
	match effect_data.effect_type:
		EffectData.EffectType.DECREASE_PERCENTAGE:
			base_amount_to_calc_change = -current_need_satisfaction
		EffectData.EffectType.DECREASE_LINEAR:
			base_amount_to_calc_change = -1.0
		EffectData.EffectType.INCREASE_LINEAR:
			base_amount_to_calc_change = 1.0
		EffectData.EffectType.CENTER_PERCENTAGE:
			base_amount_to_calc_change = 0.5 - current_need_satisfaction
	
	var need_change = game_hours_elapsed * base_amount_to_calc_change * effect_data.value
	var new_need_satisfaction = current_need_satisfaction + need_change
	new_need_satisfaction = clamp(new_need_satisfaction, 0.0, 1.0)
	need_stats[need] = new_need_satisfaction
	need_satisfaction_changed.emit(need, new_need_satisfaction)
