extends Node3D

@onready var hero: Node3D = $Hero
@onready var hero_arm: Node3D = $Hero/RightArm
@onready var orc_a: Node3D = $OrcA
@onready var orc_b: Node3D = $OrcB
@onready var flame: Node3D = $Campfire/Flame
@onready var hp_ally: ColorRect = $UI/Bars/AllyFill
@onready var hp_foe: ColorRect = $UI/Bars/FoeFill
@onready var lbl_lv: Label = $UI/TopLeft/Lv
@onready var lbl_en: Label = $UI/TopRight/En
@onready var lbl_pow: Label = $UI/Power
@onready var btn_atk: Button = $UI/Atk
@onready var btn_auto: Button = $UI/Auto
@onready var toast: Label = $UI/Toast

var lv := 1
var xp := 0
var xp_max := 120
var energy := 20
var energy_max := 20
var power := 48
var fighting := false
var auto_on := false
var hp := 100.0
var ehp := 100.0
var ehp_max := 100.0
var swing_t := 0.0
var toast_t := 0.0
var regen_t := 0.0

func _ready() -> void:
	btn_atk.pressed.connect(_on_atk)
	btn_auto.pressed.connect(_on_auto)
	_refresh_ui()
	_toast("Bosco del Falò")

func _process(delta: float) -> void:
	flame.scale.y = 1.0 + sin(Time.get_ticks_msec() * 0.012) * 0.18
	if toast_t > 0.0:
		toast_t -= delta
		toast.visible = toast_t > 0.0
	regen_t += delta
	if regen_t >= 3.5:
		regen_t = 0.0
		if energy < energy_max:
			energy += 1
			_refresh_ui()
		if auto_on and not fighting:
			_on_atk()
	if fighting:
		swing_t += delta
		var cyc := fmod(swing_t, 0.85)
		var step := 0.0
		var swing := 0.3
		if cyc < 0.18:
			swing = 0.3 + cyc * 3.0
		elif cyc < 0.32:
			swing = 0.94 - (cyc - 0.18) * 8.0
			step = (cyc - 0.18) * 2.2
		else:
			swing = -0.15 + (cyc - 0.32) * 0.35
			step = maxf(0.0, 0.28 - (cyc - 0.32))
		hero_arm.rotation.x = swing
		hero.position.x = -1.55 + step
		orc_a.rotation.z = 0.12 if cyc > 0.22 and cyc < 0.38 else 0.0
		orc_b.rotation.z = orc_a.rotation.z
	else:
		hero.position.x = -1.6
		hero.position.y = sin(Time.get_ticks_msec() * 0.003) * 0.02
		hero_arm.rotation.x = sin(Time.get_ticks_msec() * 0.002) * 0.08

func _on_atk() -> void:
	if fighting:
		return
	if energy < 2:
		_toast("Vigore insufficiente")
		return
	energy -= 2
	fighting = true
	swing_t = 0.0
	hp = 100.0
	ehp = ehp_max
	_refresh_ui()
	_fight_tick()

func _fight_tick() -> void:
	if not fighting:
		return
	await get_tree().create_timer(0.7).timeout
	if not fighting:
		return
	var dmg := 28 + randi() % 18 + lv * 3
	var taken := 6 + randi() % 6
	ehp = maxf(0.0, ehp - (20.0 + dmg / 10.0))
	hp = maxf(0.0, hp - taken)
	_refresh_ui()
	if ehp <= 0.0:
		fighting = false
		xp += 25 + lv * 4
		if xp >= xp_max:
			xp -= xp_max
			lv += 1
			xp_max = int(xp_max * 1.25)
			energy_max = 20 + lv * 2
			energy = energy_max
			_toast("Livello %d" % lv)
		else:
			_toast("Vittoria")
		power += 8 + randi() % 12
		_refresh_ui()
		return
	if hp <= 0.0:
		fighting = false
		_toast("Sconfitta")
		_refresh_ui()
		return
	_fight_tick()

func _on_auto() -> void:
	auto_on = not auto_on
	btn_auto.text = "AUTO ON" if auto_on else "AUTO OFF"
	if auto_on and not fighting:
		_on_atk()

func _refresh_ui() -> void:
	lbl_lv.text = "LVL %d · %d / %d XP" % [lv, xp, xp_max]
	lbl_en.text = "⚡ %d" % energy
	lbl_pow.text = "%d POTENZA" % power
	hp_ally.anchor_right = clampf(hp / 100.0, 0.0, 1.0)
	var ratio := 0.0 if ehp_max <= 0.0 else ehp / ehp_max
	hp_foe.anchor_right = clampf(ratio, 0.0, 1.0)
	btn_auto.text = "AUTO ON" if auto_on else "AUTO OFF"

func _toast(msg: String) -> void:
	toast.text = msg
	toast.visible = true
	toast_t = 1.6
