extends Node3D
# ETAPA 4 (protótipo): primeiro cenário explorável.
# Tudo é gerado por código para o projeto abrir sem depender de assets.
# Quando você tiver modelos 3D (Quaternius, Kenney...), substitua as caixas.

const InteractableScript := preload("res://scripts/interactable.gd")
const PlayerScript := preload("res://scripts/player.gd")
const ControlsScript := preload("res://scripts/touch_controls.gd")

var player
var ui

func _ready() -> void:
    randomize()
    _build_environment()
    _build_ground()
    _build_trees()
    _build_house(Vector3(8, 0, -8))
    _build_car(Vector3(-7, 0, -3))

    player = CharacterBody3D.new()
    player.set_script(PlayerScript)
    player.position = Vector3(0, 0.5, 6)
    add_child(player)

    ui = CanvasLayer.new()
    ui.set_script(ControlsScript)
    add_child(ui)
    ui.setup(player)
    ui.toast("Joystick à esquerda para andar, arraste à direita para olhar")

# ---------- helpers ----------
func _mat(c: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.9
    return m

func _box(pos: Vector3, size: Vector3, color: Color, parent: Node = null, collide: bool = true) -> MeshInstance3D:
    if parent == null:
        parent = self
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = _mat(color)
    mi.position = pos
    parent.add_child(mi)
    if collide:
        var sb := StaticBody3D.new()
        var cs := CollisionShape3D.new()
        var bs := BoxShape3D.new()
        bs.size = size
        cs.shape = bs
        sb.add_child(cs)
        mi.add_child(sb)
    return mi

func _make_interactable(parent: Node, local_pos: Vector3, text: String, dist: float):
    var n = Node3D.new()
    n.set_script(InteractableScript)
    n.position = local_pos
    n.action_text = text
    n.max_distance = dist
    parent.add_child(n)
    return n

# ---------- ambiente ----------
func _build_environment() -> void:
    var env := Environment.new()
    var sky := Sky.new()
    sky.sky_material = ProceduralSkyMaterial.new()
    env.background_mode = Environment.BG_SKY
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.fog_enabled = true
    env.fog_light_color = Color(0.65, 0.7, 0.72)
    env.fog_density = 0.012
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50, -30, 0)
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 45.0
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
    add_child(sun)

func _build_ground() -> void:
    _box(Vector3(0, -0.5, 0), Vector3(240, 1, 240), Color(0.28, 0.38, 0.2))
    _box(Vector3(0, 0.02, 0), Vector3(5, 0.04, 240), Color(0.15, 0.15, 0.16), null, false)

func _build_trees() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 1234
    var placed := 0
    var tries := 0
    while placed < 80 and tries < 1000:
        tries += 1
        var p := Vector2(rng.randf_range(-90, 90), rng.randf_range(-90, 90))
        if p.length() < 8.0 or absf(p.x) < 5.0:
            continue
        if p.distance_to(Vector2(8, -8)) < 10.0 or p.distance_to(Vector2(-7, -3)) < 7.0:
            continue
        _tree(p, rng)
        placed += 1

func _tree(p: Vector2, rng: RandomNumberGenerator) -> void:
    var root := StaticBody3D.new()
    root.position = Vector3(p.x, 0, p.y)
    add_child(root)
    var cs := CollisionShape3D.new()
    var cyl := CylinderShape3D.new()
    cyl.radius = 0.25
    cyl.height = 3.0
    cs.shape = cyl
    cs.position.y = 1.5
    root.add_child(cs)
    var trunk := MeshInstance3D.new()
    var tm := CylinderMesh.new()
    tm.top_radius = 0.15
    tm.bottom_radius = 0.22
    tm.height = 3.0
    trunk.mesh = tm
    trunk.material_override = _mat(Color(0.3, 0.2, 0.12))
    trunk.position.y = 1.5
    root.add_child(trunk)
    var leaves := MeshInstance3D.new()
    var lm := CylinderMesh.new()
    lm.top_radius = 0.0
    lm.bottom_radius = rng.randf_range(1.2, 1.9)
    lm.height = 3.5
    leaves.mesh = lm
    leaves.material_override = _mat(Color(0.1, rng.randf_range(0.25, 0.35), 0.12))
    leaves.position.y = 4.2
    root.add_child(leaves)

# ---------- casa explorável ----------
func _build_house(origin: Vector3) -> void:
    var house := Node3D.new()
    house.position = origin
    add_child(house)
    var wall := Color(0.6, 0.55, 0.48)
    _box(Vector3(0, 0.015, 0), Vector3(8, 0.03, 6), Color(0.25, 0.2, 0.16), house, false)
    _box(Vector3(0, 1.5, -3), Vector3(8, 3, 0.2), wall, house)
    _box(Vector3(-4, 1.5, 0), Vector3(0.2, 3, 6), wall, house)
    _box(Vector3(4, 1.5, 0), Vector3(0.2, 3, 6), wall, house)
    _box(Vector3(-2.35, 1.5, 3), Vector3(3.3, 3, 0.2), wall, house)
    _box(Vector3(2.35, 1.5, 3), Vector3(3.3, 3, 0.2), wall, house)
    _box(Vector3(0, 2.55, 3), Vector3(1.4, 0.9, 0.2), wall, house)
    _box(Vector3(0, 3.1, 0), Vector3(8.6, 0.2, 6.6), Color(0.35, 0.18, 0.15), house)
    var lamp := OmniLight3D.new()
    lamp.position = Vector3(0, 2.5, 0)
    lamp.omni_range = 8.0
    lamp.light_energy = 1.2
    house.add_child(lamp)

    # Porta com dobradiça
    var hinge := Node3D.new()
    hinge.position = Vector3(-0.7, 0, 3)
    house.add_child(hinge)
    _box(Vector3(0.7, 1.05, 0), Vector3(1.4, 2.1, 0.1), Color(0.4, 0.26, 0.14), hinge)
    var door_state := {"open": false}
    var door_it = _make_interactable(house, Vector3(0, 1, 3), "ABRIR", 2.4)
    door_it.on_interact = func(_p):
        door_state.open = not door_state.open
        var tw := create_tween()
        var target_angle := deg_to_rad(-95.0) if door_state.open else 0.0
        tw.tween_property(hinge, "rotation:y", target_angle, 0.35)
        door_it.action_text = "FECHAR" if door_state.open else "ABRIR"

    # Armário (vasculhar uma vez)
    _box(Vector3(-3.3, 0.8, -2.6), Vector3(0.8, 1.6, 0.5), Color(0.35, 0.25, 0.18), house)
    var cab_state := {"done": false}
    var cab_it = _make_interactable(house, Vector3(-3.3, 1.0, -2.2), "VASCULHAR", 2.0)
    cab_it.on_interact = func(_p):
        if cab_state.done:
            return
        cab_state.done = true
        var loot := ["Lata de feijão", "Garrafa d'água", "Bandagem", "Faca de cozinha"]
        var got: String = loot[randi() % loot.size()]
        player.add_item(got)
        ui.toast("Encontrou: " + got)
        cab_it.remove_from_group("interactable")
        player.refresh_target()

    # Item no chão
    var can := _box(Vector3(2.5, 0.12, -1.5), Vector3(0.14, 0.24, 0.14), Color(0.8, 0.6, 0.1), house, false)
    var can_it = _make_interactable(can, Vector3.ZERO, "PEGAR", 1.8)
    can_it.on_interact = func(_p):
        player.add_item("Lata de comida")
        ui.toast("Pegou: Lata de comida")
        can_it.remove_from_group("interactable")
        can.queue_free()
        player.refresh_target()

# ---------- veículo danificado ----------
func _build_car(pos: Vector3) -> void:
    var car := Node3D.new()
    car.position = pos
    car.rotation.y = 0.4
    add_child(car)
    _box(Vector3(0, 0.65, 0), Vector3(2.0, 0.7, 4.2), Color(0.45, 0.1, 0.08), car)
    _box(Vector3(0, 1.3, -0.2), Vector3(1.8, 0.6, 2.0), Color(0.3, 0.08, 0.06), car, false)
    for sx in [-1.0, 1.0]:
        for sz in [-1.3, 1.3]:
            var w := MeshInstance3D.new()
            var cm := CylinderMesh.new()
            cm.top_radius = 0.38
            cm.bottom_radius = 0.38
            cm.height = 0.3
            w.mesh = cm
            w.material_override = _mat(Color(0.05, 0.05, 0.05))
            w.rotation.z = PI / 2.0
            w.position = Vector3(sx, 0.38, sz)
            car.add_child(w)
    var it = _make_interactable(car, Vector3(0, 1.0, 0), "INSPECIONAR", 3.2)
    it.on_interact = func(_p):
        ui.toast("Sem combustível, bateria morta e sem o motor de arranque.")
