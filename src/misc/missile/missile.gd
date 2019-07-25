extends Area2D
class_name Missile

signal hit(spll)

var spawn_pos: Vector2 = Vector2()
var weapon_miss_type: String = ""
var weapon_type: String = ""
var target setget set_target
var spell: Spell setget set_spell
var user = null
var instant_spawn: bool = false
var reverse: bool = false
var rotate: bool = false
var hit: bool = false

func _ready():
	set_process(false)
	randomize()

func _process(delta: float):
	if not hit and rotate:
		look_at(target.get_center_pos())
	$tween.interpolate_property(self, @":global_position", get_global_position(), target.get_center_pos(), \
	spawn_pos.distance_to(target.get_center_pos()) / user.weapon_range, Tween.TRANS_CIRC, Tween.EASE_OUT)
	$tween.start()

func _on_projectile_area_entered(area):
	if area.get_owner() == target and not hit:
		set_z_index(1)
		hit = true
		emit_signal("hit", spell)
		if $img.get_texture():
			if not spell:
				$anim.play("fade")
			else:
				$anim.play("img_fade")
		if not target.dead:
			attack(target)

func _on_anim_animation_finished(anim_name):
	if anim_name == "fade":
		set_process(false)
		$tween.remove_all()
		queue_free()

func set_target(value):
	target = value
	spawn_pos = user.get_node(@"img/missile").get_global_position()
	if rotate:
		look_at(target.get_center_pos())
	if instant_spawn:
		show()
		set_global_position(target.get_center_pos())
	if reverse:
		target = user
		set_process(true)
	if not instant_spawn:
		set_process(true)
		show()

func set_spell(value):
	spell = value

func fade():
	$anim.play("fade")

func attack(unit=target, ignore_armor=false, attack_table=Stats.attack_table.ranged):
	var dice_roll: int = randi() % 100 + 1
	var damage: int = int(round(rand_range(user.min_damage, user.max_damage)))
	var snd_idx: int = randi() % globals.weapon_type[weapon_type]
	var snd: String = ""
	var play_sound: bool = true
	if spell:
		damage = int(round(damage * spell.cast(true)))
		ignore_armor = spell.ignore_armor
		attack_table = spell.attack_table
		unit.set_spell(spell)
		if spell.has_node(spell.spell_name):
			play_sound = spell.get_node(spell.spell_name).play_sound
	if dice_roll <= attack_table.hit:
		unit.take_damage(damage, "hit", user, ignore_armor)
		snd = "%s%s" % [weapon_type, snd_idx]
	elif dice_roll <= attack_table.critical:
		unit.take_damage(damage * 2, "critical", user, ignore_armor)
		snd = "%s%s" % [weapon_type, snd_idx]
	elif dice_roll <= attack_table.dodge and not unit.is_class("StaticBody2D"):
		unit.take_damage(0, "dodge", user)
		snd = "%s%s" % [weapon_miss_type, randi() % 6]
	else:
		unit.take_damage(0, "miss", user)
		snd = "%s%s" % [weapon_miss_type, randi() % 6]
	if play_sound:
		globals.play_sample(snd, $snd)

func make():
	weapon_type = "arrow_hit_armor" # this for now till I get a new snd
	weapon_miss_type = "arrow_pass" # this for now till I get a new snd
	var meta: Dictionary = {"tex":"res://asset/img/missile-spell/%s.res", "size":"big",
				"race":user.get_node(@"img").get_texture().get_path().get_base_dir().get_file()}
	if meta.race == "gnoll" or meta.race == "goblin":
		$img.set_offset(Vector2(-5.5, 0.0))
		meta.size = "small"
	if spell:
		meta.sname = spell.get_name()
		var i: Resource = load("res://src/spell/effects/%s.tscn" % meta.sname)
		if i != null:
			var effect: SpellEffect = i.instance()
			connect("hit", effect, "on_hit")
			if meta.sname != "slow":
				effect.connect("unmake", self, "fade")
			add_child(effect)
			effect.set_owner(self)
		match meta.sname:
			"fireball", "shadow_bolt", "frost_bolt", "mind_blast", "slow", "siphon_mana":
				$coll.set_shape(load("res://asset/img/missile-spell/spell_coll.res"))
				match meta.sname:
					"mind_blast", "slow":
						instant_spawn = true
					"siphon_mana":
						instant_spawn = true
						reverse = true
					"frost_bolt":
						rotate = true
			"concussive_shot":
				meta.tex = meta.tex % "arrow_%s2"
			"piercing_shot":
				meta.tex = meta.tex % "arrow_%s1"
			"explosive_arrow":
				meta.tex = meta.tex % "arrow_%s3"
			_:
				if "shot" in meta.sname or "arrow" in meta.sname or meta.sname == "volley":
					meta.tex = meta.tex % "arrow_%s0"
	else:
		meta.tex = meta.tex % "arrow_%s0"
	if "%s" in meta.tex and "arrow" in meta.tex:
		meta.tex = meta.tex % meta.size
		rotate = true
		$coll.set_position(Vector2(-6.0, 0.0))
		weapon_type = "arrow_hit_armor"
		weapon_miss_type = "arrow_pass"
		$img.set_texture(load(meta.tex))
