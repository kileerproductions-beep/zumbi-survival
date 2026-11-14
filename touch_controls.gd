extends CanvasLayer
# ETAPA 2/3: controles mobile e interface limpa.
# Esquerda da tela: joystick flutuante. Direita: arrastar para girar a câmera.
# Botões fixos: PULAR e INVENTÁRIO. O botão de interação só aparece perto de algo.

class JoyView extends Control:
    var active := false
    var base := Vector2.ZERO
    var knob := Vector2.ZERO
    var radius := 90.0

    func _draw() -> void:
        var b: Vector2 = base if active else Vector2(170.0, size.y - 170.0)
        var k: Vector2 = knob if active else b
        var a := 0.35 if active else 0.12
        draw_circle(b, radius, Color(1, 1, 1, a * 0.4))
        draw_arc(b, radius, 0.0, TAU, 48, Color(1, 1, 1, a), 2.0)
        draw_circle(k, 34.0, Color(1, 1, 1, a))

var player
var root: Control
var joy: JoyView
var btn_jump: Button
var btn_inv: Button
var btn_interact: Button
var toast_label: Label
var panel: PanelContainer
var inv_text: Label
var joy_index := -1
var cam_index := -1
var _toast_tw: Tween

func setup(p: Node) -> void:
    player = p
    root = Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    joy = JoyView.new()
    joy.set_anchors_preset(Control.PRESET_FULL_RECT)
    joy.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(joy)

    btn_jump = _make_button("PULAR", Color(0, 0, 0, 0.35))
    _place(btn_jump, -170, -170, -50, -50, 1.0, 1.0)
    btn_jump.pressed.connect(func(): player.jump_queued = true)

    btn_interact = _make_button("", Color(0.75, 0.45, 0.1, 0.8))
    _place(btn_interact, -400, -200, -190, -110, 1.0, 1.0)
    btn_interact.visible = false
    btn_interact.pressed.connect(func(): player.try_interact())

    btn_inv = _make_button("INVENTÁRIO", Color(0, 0, 0, 0.35))
    _place(btn_inv, -210, 30, -30, 90, 1.0, 0.0)
    btn_inv.pressed.connect(_toggle_inventory)

    toast_label = Label.new()
    toast_label.anchor_left = 0.5
    toast_label.anchor_right = 0.5
    toast_label.offset_left = -400
    toast_label.offset_right = 400
    toast_label.offset_top = 40
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    toast_label.add_theme_font_size_override("font_size", 26)
    toast_label.add_theme_color_override("font_outline_color", Color.BLACK)
    toast_label.add_theme_constant_override("outline_size", 6)
    toast_label.modulate.a = 0.0
    root.add_child(toast_label)

    panel = PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
    panel.grow_vertical = Control.GROW_DIRECTION_BOTH
    panel.custom_minimum_size = Vector2(440, 300)
    panel.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0.8)))
    panel.visible = false
    root.add_child(panel)
    var box := VBoxContainer.new()
    panel.add_child(box)
    var title := Label.new()
    title.text = "INVENTÁRIO"
    title.add_theme_font_size_override("font_size", 28)
    box.add_child(title)
    inv_text = Label.new()
    inv_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
    inv_text.add_theme_font_size_override("font_size", 22)
    box.add_child(inv_text)
    var close := Button.new()
    close.text = "FECHAR"
    close.focus_mode = Control.FOCUS_NONE
    close.custom_minimum_size = Vector2(0, 56)
    close.pressed.connect(_toggle_inventory)
    box.add_child(close)

    player.target_changed.connect(_on_target_changed)

func _style(c: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = c
    s.set_corner_radius_all(18)
    s.set_border_width_all(2)
    s.border_color = Color(1, 1, 1, 0.35)
    return s

func _make_button(text: String, color: Color) -> Button:
    var b := Button.new()
    b.text = text
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_stylebox_override("normal", _style(color))
    b.add_theme_stylebox_override("hover", _style(color))
    b.add_theme_stylebox_override("pressed", _style(color.lightened(0.3)))
    b.add_theme_font_size_override("font_size", 22)
    root.add_child(b)
    return b

func _place(b: Control, l: float, t: float, r: float, bt: float, ax: float, ay: float) -> void:
    b.anchor_left = ax
    b.anchor_right = ax
    b.anchor_top = ay
    b.anchor_bottom = ay
    b.offset_left = l
    b.offset_top = t
    b.offset_right = r
    b.offset_bottom = bt

func _on_target_changed(text: String) -> void:
    btn_interact.visible = text != ""
    btn_interact.text = text

func toast(text: String) -> void:
    toast_label.text = text
    toast_label.modulate.a = 1.0
    if _toast_tw != null and _toast_tw.is_valid():
        _toast_tw.kill()
    _toast_tw = create_tween()
    _toast_tw.tween_interval(2.2)
    _toast_tw.tween_property(toast_label, "modulate:a", 0.0, 0.6)

func _toggle_inventory() -> void:
    panel.visible = not panel.visible
    if panel.visible:
        if player.inventory.is_empty():
            inv_text.text = "Vazio"
        else:
            var lines := PackedStringArray()
            for k in player.inventory:
                lines.append("%s  x%d" % [k, player.inventory[k]])
            inv_text.text = "\n".join(lines)

func _over_button(pos: Vector2) -> bool:
    for b in [btn_jump, btn_inv, btn_interact]:
        if b.visible and b.get_global_rect().has_point(pos):
            return true
    return false

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            if panel.visible or _over_button(event.position):
                return
            var half := get_viewport().get_visible_rect().size.x * 0.5
            if event.position.x < half:
                if joy_index == -1:
                    joy_index = event.index
                    joy.active = true
                    joy.base = event.position
                    joy.knob = event.position
                    joy.queue_redraw()
            elif cam_index == -1:
                cam_index = event.index
        else:
            if event.index == joy_index:
                joy_index = -1
                joy.active = false
                player.move_input = Vector2.ZERO
                joy.queue_redraw()
            elif event.index == cam_index:
                cam_index = -1
    elif event is InputEventScreenDrag:
        if event.index == joy_index:
            var off: Vector2 = event.position - joy.base
            if off.length() > joy.radius:
                off = off.normalized() * joy.radius
            joy.knob = joy.base + off
            player.move_input = off / joy.radius
            joy.queue_redraw()
        elif event.index == cam_index:
            player.rotate_camera(event.relative)
