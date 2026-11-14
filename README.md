# Zumbi Survival (Godot 4.3+)
[gd_scene load_steps=2 format=3]
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://main.gd" id="1"]

[node name="Main" type="Node3D"]
script = ExtResource("1")

[node name="Main" type="Node3D"]
script = ExtResource("1")
Etapas 1-4 (protótipo): personagem, câmera, controles mobile, interação contextual e primeiro cenário (casa, carro, floresta).

## Rodar no PC
1. Instale o Godot 4.3 ou mais novo (versão "Standard", não .NET).
2. Importe a pasta (project.godot) e aperte F5.
3. Teste: WASD (Ctrl = andar), mouse na direita da tela gira a câmera, Espaço pula, E interage.
   Com o mouse, a metade esquerda da tela funciona como joystick.

## Gerar o APK
1. Instale o JDK 17 e o Android SDK (Android Studio instala o SDK).
2. Godot > Editor > Editor Settings > Export > Android: informe os caminhos do SDK e do JDK.
3. Projeto > Exportar > Adicionar > Android. Marque só arm64-v8a. Defina um nome de pacote (ex.: com.seunome.zumbi).
4. Exporte o APK (debug) e instale no celular, ou ligue a depuração USB e use o botão de "deploy remoto".

## Calibrar a movimentação
Em scripts/player.gd, no topo: WALK_SPEED, RUN_SPEED, JUMP_HEIGHT, GROUND_ACCEL.

## Mecânica de movimento
Joystick até o fim = correr. Joystick parcial = andar mais devagar.

## Próximas etapas
5 zumbis e IA, 6 inventário e saque, 7 sobrevivência e armas, 8 veículos, 9 mapa/clima/áudio, 10 otimização.
