extends Node3D
# Ponto interativo. O jogador detecta estes nós pelo grupo "interactable".
# Quando o jogador chega perto, o botão contextual aparece com action_text.

var action_text: String = "INTERAGIR"
var max_distance: float = 2.2
var on_interact: Callable = Callable()

func _ready() -> void:
    add_to_group("interactable")

func interact(player: Node) -> void:
    if on_interact.is_valid():
        on_interact.call(player)
