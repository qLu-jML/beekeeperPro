import re

with open('c:/Users/ntbde/OneDrive/Documents/GitHub/beekeeperPro/scenes/main.tscn', 'r') as f:
    lines = f.readlines()

ext_resources = [line for line in lines if line.startswith('[ext_resource')]
sub_resources = []
in_tileset = False
for line in lines:
    if line.startswith('[sub_resource type="TileSetAtlasSource"') or line.startswith('[sub_resource type="TileSet"'):
        in_tileset = True
    elif line.startswith('[sub_resource type="RectangleShape2D"'):
        in_tileset = False
    
    if in_tileset:
        sub_resources.append(line)

# Generate Layer 0 Tile Data
layer0_data = []

# Fill background with grass (source_id 0, atlas_coords 0,0)
for cy in range(-5, 25):
    for cx in range(-5, 35):
        coord = (cx & 0xFFFF) | ((cy & 0xFFFF) << 16)
        source_id = 0
        atlas_coord = 0
        layer0_data.extend([coord, source_id, atlas_coord])

# Add 3 Dirt apiary patches
# Tilled dirt is source_id 2. 
apiary_centers_x = [7, 15, 23]
apiary_y = 5

for ax in apiary_centers_x:
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            cx = ax + dx
            cy = apiary_y + dy
            coord = (cx & 0xFFFF) | ((cy & 0xFFFF) << 16)
            
            # Map dx, dy to atlas_coords 0,1,2
            atlas_x = dx + 1
            atlas_y = dy + 1
            atlas_coord = (atlas_x & 0xFFFF) | ((atlas_y & 0xFFFF) << 16)
            
            # source_id 2 is Tilled_Dirt
            layer0_data.extend([coord, 2, atlas_coord])

layer0_str = ", ".join(map(str, layer0_data))

out_lines = []
out_lines.append('[gd_scene format=3 uid="uid://farmtest123"]\n\n')
out_lines.extend(ext_resources)
out_lines.append('[ext_resource type="PackedScene" uid="uid://d66jla5610ht" path="res://scenes/hive.tscn" id="99_hive"]\n')
out_lines.append('[ext_resource type="PackedScene" uid="uid://b1beifh2xohy4" path="res://scenes/flowers/flowers.tscn" id="98_flower"]\n')
out_lines.append('[ext_resource type="PackedScene" uid="uid://d3qdbfmsmyqoa" path="res://scenes/player/player.tscn" id="97_player"]\n')

out_lines.append('\n')
out_lines.extend(sub_resources)
out_lines.append('\n')
out_lines.append('[node name="TestEnvironment" type="Node2D"]\n\n')

out_lines.append('[node name="TileMap" type="TileMap" parent="."]\n')
out_lines.append('tile_set = SubResource("TileSet_o6xl0")\n')
out_lines.append('format = 2\n')
out_lines.append(f'layer_0/tile_data = PackedInt32Array({layer0_str})\n')
out_lines.append('\n')

out_lines.append('[node name="Objects" type="Node2D" parent="."]\n')
out_lines.append('y_sort_enabled = true\n\n')

hive_id_counter = 1
flower_id_counter = 1

# Place Hives and Flowers
for i, ax in enumerate(apiary_centers_x):
    # Hive in the center of the dirt
    px = ax * 16 + 8
    py = apiary_y * 16 + 8
    out_lines.append(f'[node name="Hive_{hive_id_counter}" parent="Objects" instance=ExtResource("99_hive")]\n')
    out_lines.append(f'position = Vector2({px}, {py})\n\n')
    hive_id_counter += 1
    
    # 3 Flowers below the dirt
    for fx in range(-1, 2):
        f_px = (ax + fx) * 16 + 8
        f_py = (apiary_y + 3) * 16 + 8
        out_lines.append(f'[node name="Flower_{flower_id_counter}" parent="Objects" instance=ExtResource("98_flower")]\n')
        out_lines.append(f'position = Vector2({f_px}, {f_py})\n\n')
        flower_id_counter += 1

out_lines.append('[node name="Player" parent="Objects" instance=ExtResource("97_player")]\n')
out_lines.append('position = Vector2(120, 160)\n\n')

out_lines.append('[node name="Camera2D" type="Camera2D" parent="Objects/Player"]\n')
out_lines.append('zoom = Vector2(2.5, 2.5)\n')

with open('c:/Users/ntbde/OneDrive/Documents/GitHub/beekeeperPro/scenes/TestEnvironment.tscn', 'w') as f:
    f.writelines(out_lines)

print("Python script executed correctly. Three apiaries built.")
