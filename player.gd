extends CharacterBody3D
# ETAPA 1: personagem e movimentação.
# Ajuste os números abaixo para calibrar a sensação de movimento.

signal target_changed(text: String)

const WALK_SPEED := 2.0       # m/s, caminhada natural
const RUN_SPEED := 4.6        # m/s, corrida (trote), nem lenta nem exagerada
const JUMP_HEIGHT := 0.9      # metros, pulo moderado
const GRAVITY := 19.6
const GROUND_ACCEL := 10.0    # aceleração: dá sensação de peso
const GROUND_DECEL := 12.0
const AIR_ACCEL := 2.5
const CAM_SENS := 0.005

var move_input := Vector2.ZERO   # preenchido pelo joystick virtual
var jump_queued := false
var cam_yaw := 0.0
var cam_pitch := -0.3
var inventory: Dictionary = {}
var current_target = null

var rig: Node3D
var arm: SpringArm3D
var visual: Node3D
var body_node: Node3D
var leg_l: Node3D
var leg_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var _scan_timer := 0.0
var _anim_t := 0.0

func _ready() -> void:
    var cs := CollisionShape3D.new()
    var cap := CapsuleShape3D.new()
    cap.radius = 0.35
    cap.height = 1.75
    cs.shape = cap
    cs.position.y = 0.875
    add_child(cs)
    floor_snap_length = 0.3
    _build_visual()
    _build_camera()

# ---------- construção do corpo (placeholder procedural) ----------
func _mesh_node(mesh: Mesh, color: Color, pos: Vector3, parent: Node3D) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.9
    mi.material_override = m
    mi.position = pos
    parent.add_child(mi)
    return mi

func _limb(parent: Node3D, pivot_pos: Vector3, size: Vector3, color: Color) -> Node3D:
    var pivot := Node3D.new()
    pivot.position = pivot_pos
    parent.add_child(pivot)
    var bm := BoxMesh.new()
    bm.size = size
    _mesh_node(bm, color, Vector3(0, -size.y * 0.5, 0), pivot)
    return pivot

func _build_visual() -> void:
    visual = Node3D.new()
    add_child(visual)
    body_node = Node3D.new()
    visual.add_child(body_node)
    var cloth := Color(0.25, 0.32, 0.22)
    var pants := Color(0.2, 0.22, 0.3)
    var skin := Color(0.8, 0.65, 0.55)
    var torso := BoxMesh.new()
    torso.size = Vector3(0.5, 0.65, 0.28)
    _mesh_node(torso, cloth, Vector3(0, 1.15, 0), body_node)
    var head := SphereMesh.new()
    head.radius = 0.14
    head.height = 0.28
    _mesh_node(head, skin, Vector3(0, 1.62, 0), body_node)
    var nose := BoxMesh.new()
    nose.size = Vector3(0.06, 0.06, 0.1)
    _mesh_node(nose, skin, Vector3(0, 1.62, -0.14), body_node)
    leg_l = _limb(body_node, Vector3(-0.13, 0.82, 0), Vector3(0.18, 0.82, 0.2), pants)
    leg_r = _limb(body_node, Vector3(0.13, 0.82, 0), Vector3(0.18, 0.82, 0.2), pants)
    arm_l = _limb(body_node, Vector3(-0.33, 1.45, 0), Vector3(0.12, 0.62, 0.14), cloth)
    arm_r = _limb(body_node, Vector3(0.33, 1.45, 0), Vector3(0.12, 0.62, 0.14), cloth)

# ---------- ETAPA 2: câmera em terceira pessoa ----------
func _build_camera() -> void:
    rig = Node3D.new()
    rig.position = Vector3(0, 1.5, 0)
    add_child(rig)
    arm = SpringArm3D.new()
    arm.spring_length = 3.2
    arm.margin = 0.3
    arm.collision_mask = 1
    arm.add_excluded_object(get_rid())
    rig.add_child(arm)
    var cam := Camera3D.new()
    cam.fov = 70.0
    cam.far = 250.0
    arm.add_child(cam)
    cam.current = true

func rotate_camera(rel: Vector2) -> void:
    cam_yaw -= rel.x * CAM_SENS
    cam_pitch = clampf(cam_pitch - rel.y * CAM_SENS, -1.1, 0.4)

# ---------- entrada ----------
func _read_move_input() -> Vector2:
    if move_input.length() > 0.05:
        return move_input
    # Teclado para testar no PC: WASD / setas (Ctrl = andar)
    var v := Vector2.ZERO
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        v.x += 1.0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        v.x -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        v.y += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        v.y -= 1.0
    if v != Vector2.ZERO:
        v = v.normalized()
        if Input.is_key_pressed(KEY_CTRL):
            v *= 0.5
    return v

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_SPACE:
            jump_queued = true
        elif event.keycode == KEY_E:
            try_interact()

# ---------- física ----------
func _physics_process(delta: float) -> void:
    var inp := _read_move_input()
    var mag := clampf(inp.length(), 0.0, 1.0)
    var dir := Vector3.ZERO
    var target_speed := 0.0
    if mag > 0.1:
        dir = Vector3(inp.x, 0.0, inp.y).rotated(Vector3.UP, cam_yaw).normalized()
        # joystick quase no máximo = corrida; parcial = caminhada proporcional
        if mag >= 0.85:
            target_speed = RUN_SPEED
        else:
            target_speed = WALK_SPEED * (mag / 0.85)

    var horizontal := Vector3(velocity.x, 0.0, velocity.z)
    var accel := GROUND_ACCEL
    if not is_on_floor():
        accel = AIR_ACCEL
    elif target_speed == 0.0:
        accel = GROUND_DECEL
    horizontal = horizontal.move_toward(dir * target_speed, accel * delta)
    velocity.x = horizontal.x
    velocity.z = horizontal.z

    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0
    if jump_queued and is_on_floor():
        velocity.y = sqrt(2.0 * GRAVITY * JUMP_HEIGHT)
    jump_queued = false
    move_and_slide()

    _scan_timer -= delta
    if _scan_timer <= 0.0:
        _scan_timer = 0.1
        _update_target()

func _process(delta: float) -> void:
    rig.rotation.y = cam_yaw
    arm.rotation.x = cam_pitch
    _animate(delta)

func _animate(delta: float) -> void:
    var h := Vector2(velocity.x, velocity.z).length()
    var k := clampf(h / RUN_SPEED, 0.0, 1.0)
    if is_on_floor():
        _anim_t += delta * h * 2.4
        var swing := k * 0.9
        var s := sin(_anim_t)
        leg_l.rotation.x = s * swing
        leg_r.rotation.x = -s * swing
        arm_l.rotation.x = -s * swing * 0.8
        arm_r.rotation.x = s * swing * 0.8
        body_node.position.y = absf(s) * 0.05 * k
    else:
        leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.5, 10.0 * delta)
        leg_r.rotation.x = lerpf(leg_r.rotation.x, -0.3, 10.0 * delta)
        arm_l.rotation.x = lerpf(arm_l.rotation.x, -0.6, 10.0 * delta)
        arm_r.rotation.x = lerpf(arm_r.rotation.x, -0.6, 10.0 * delta)
    body_node.rotation.x = lerpf(body_node.rotation.x, -k * 0.12, 8.0 * delta)
    if h > 0.3:
        visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-velocity.x, -velocity.z), 10.0 * delta)

# ---------- ETAPA 3: interação contextual ----------
func _update_target() -> void:
    if current_target != null and not is_instance_valid(current_target):
        current_target = null
    var best = null
    var best_d := INF
    var nodes := get_tree().get_nodes_in_group("interactable")
    for i in range(nodes.size()):
        var n = nodes[i]
        var d := global_position.distance_to(n.global_position)
        var md: float = n.get("max_distance")
        if d <= md and d < best_d:
            best = n
            best_d = d
    if best != current_target:
        current_target = best
        if best == null:
            target_changed.emit("")
        else:
            target_changed.emit(str(best.get("action_text")))

func try_interact() -> void:
    if current_target != null and is_instance_valid(current_target):
        current_target.call("interact", self)
    refresh_target()

func refresh_target() -> void:
    current_target = null
    _scan_timer = 0.0

func add_item(item_name: String, qty: int = 1) -> void:
    inventory[item_name] = int(inventory.get(item_name, 0)) + qty
