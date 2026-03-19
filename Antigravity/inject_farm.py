import re

def parse_int_array(data_str):
    if not data_str.strip(): return []
    ints = [int(x.strip()) for x in data_str.strip('() \n\r').split(',')]
    cells = {}
    for i in range(0, len(ints), 3):
        cells[ints[i]] = [ints[i+1], ints[i+2]]
    return cells

def serialize_int_array(cells):
    ints = []
    for coord, data in cells.items():
        ints.extend([coord, data[0], data[1]])
    return "PackedInt32Array(" + ", ".join(map(str, ints)) + ")"

with open('c:/Users/ntbde/OneDrive/Documents/GitHub/beekeeperPro/scenes/main.tscn', 'r') as f:
    original_lines = f.readlines()

out_lines = []

# We want to filter out the old Hive and Garden nodes, and inject our own.
in_hive = False
in_garden = False
in_tilemap = False

tilemap_lines = []
layer0_line_idx = -1
layer1_line_idx = -1

for i, line in enumerate(original_lines):
    # Rename root node
    if line.startswith('[node name="main"'):
        out_lines.append(line.replace('"main"', '"TestEnvironment"'))
        continue
        
    # We want to skip old hive and old garden
    if line.startswith('[node name="Hive"'):
        in_hive = True
        continue
    if in_hive and line.startswith('['):
        in_hive = False
        
    if line.startswith('[node name="Garden"'):
        in_garden = True
        continue
    if in_garden and line.startswith('['):
        in_garden = False
        
    if in_hive or in_garden:
        continue

    # We want to intercept the Tilemap layer_0/tile_data to add dirt
    if line.startswith('layer_0/tile_data = '):
        # Decode
        data_str = line.split('=', 1)[1].strip()
        cells = parse_int_array(data_str[len('PackedInt32Array('):-1].strip())
        
        # Inject 3 apiaries at tile coords y=12, x=6, 14, 22
        apiary_centers_x = [6, 14, 22]
        apiary_y = 12
        for ax in apiary_centers_x:
            for dx in range(-1, 2):
                for dy in range(-1, 2):
                    cx = ax + dx
                    cy = apiary_y + dy
                    coord = (cx & 0xFFFF) | ((cy & 0xFFFF) << 16)
                    atlas_x = dx + 1
                    atlas_y = dy + 1
                    atlas_coord = (atlas_x & 0xFFFF) | ((atlas_y & 0xFFFF) << 16)
                    cells[coord] = [2, atlas_coord] # Source 2 is Tilled Dirt
                    
        # Re-encode and write
        out_lines.append('layer_0/tile_data = ' + serialize_int_array(cells) + '\n')
        continue
        
    out_lines.append(line)

# Now, we must inject our 3 Hives and 9 Flowers into the World node.
# We will just append them at the end of the file. No, they must be children of World.
# Actually, since scenes format just relies on parent paths, we can define them anywhere.
# Let's define them at the end.
apiary_centers_x = [6, 14, 22]
apiary_y = 12

hive_id = 1
flower_id = 1
for ax in apiary_centers_x:
    px = ax * 16 + 8
    py = apiary_y * 16 + 8
    
    out_lines.append('\n')
    out_lines.append(f'[node name="ApiaryHive_{hive_id}" parent="World" instance=ExtResource("1_sugp2")]\n')
    out_lines.append(f'position = Vector2({px}, {py})\n')
    hive_id += 1
    
    for fx in range(-1, 2):
        f_px = (ax + fx) * 16 + 8
        f_py = (apiary_y + 3) * 16 + 8
        out_lines.append('\n')
        out_lines.append(f'[node name="ApiaryFlower_{flower_id}" parent="World" instance=ExtResource("2_jyhfs")]\n')
        out_lines.append(f'position = Vector2({f_px}, {f_py})\n')
        flower_id += 1

with open('c:/Users/ntbde/OneDrive/Documents/GitHub/beekeeperPro/scenes/TestEnvironment.tscn', 'w') as f:
    f.writelines(out_lines)

print("Godot scene perfectly replicated and expanded.")
