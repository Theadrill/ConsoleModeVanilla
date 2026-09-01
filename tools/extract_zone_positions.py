import pathlib, struct

def load_dbc(path):
    data = pathlib.Path(path).read_bytes()
    magic, records, fields, rec_size, str_size = struct.unpack_from('<4sIIII', data, 0)
    hdr = 20
    rec_data = data[hdr:hdr+records*rec_size]
    strs = data[hdr+records*rec_size:]
    return records, fields, rec_size, rec_data, strs

def gstr(st, off):
    if off >= len(st) or off <= 0:
        return ""
    j = st.find(b'\x00', off)
    if j == -1:
        return st[off:].decode('utf-8', errors='ignore')
    return st[off:j].decode('utf-8', errors='ignore')

# Load AreaTable (patch has turtle customs)
patch_area = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode\patch_AreaTable.dbc")
rec_a, fields_a, rs_a, rd_a, st_a = load_dbc(patch_area)
print(f"AreaTable patch: records={rec_a} fields={fields_a}")

# field 11 is enUS name for fields=25 (as discovered). For fields=21 old, field maybe different but we use patch.
# Build ID -> name map (enUS)
id_to_name = {}
for i in range(rec_a):
    off = i*rs_a
    vals = struct.unpack_from('<' + 'I'*fields_a, rd_a, off)
    aid = vals[0]
    # fields: try field 11 for enUS
    en_off = vals[11] if fields_a > 11 else 0
    name = gstr(st_a, en_off)
    if name:
        id_to_name[aid] = name

# Check some known
for tid in [406, 15, 331, 16, 141, 148, 1657,1637, 1638, 1497, 1519, 1537]:
    print(f"ID {tid} -> {id_to_name.get(tid, 'MISSING')}")

# Load WorldMapArea (use patch version which has Silithus corrected? also dbc has older)
# We'll use patch_WorldMapArea as more recent, but also check dbc for comparison
patch_wma = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode\patch_WorldMapArea.dbc")
rec_w, fields_w, rs_w, rd_w, st_w = load_dbc(patch_wma)
print(f"WMA patch: records={rec_w}")

# Need dbc also for fallback?
dbc_wma = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode\dbc_WorldMapArea.dbc")
rec_w2, fields_w2, rs_w2, rd_w2, st_w2 = load_dbc(dbc_wma)

# Find continent bounds
def find_continents(rec_data, rec_size, records):
    bounds = {}
    for i in range(records):
        off = i*rec_size
        v = struct.unpack_from('<IIIIffff', rec_data, off)
        # v: ID, MapID, AreaID, NameOff, L, R, T, B
        if v[2] == 0: # AreaID 0 means continent itself
            name = gstr(st_w, v[3]) if rec_data is rd_w else gstr(st_w2, v[3])
            print(f"Continent ID={v[0]} Map={v[1]} name='{name}' L={v[4]:.1f} R={v[5]:.1f} T={v[6]:.1f} B={v[7]:.1f}")
            # Store per MapID
            # need to get string for patch vs dbc
            bounds[v[1]] = (v[4], v[5], v[6], v[7])  # Left, Right, Top, Bottom
    return bounds

bounds = find_continents(rd_w, rs_w, rec_w)
print("bounds", bounds)
# Verify konts: Map 0 = Azeroth, Map 1 = Kalimdor
# L,R,T,B as floats
# For Kalimdor: L=17066.6 R=-19733.2 etc
# Compute normalized positions

# Build map for each WMA entry
zones = []
for i in range(rec_w):
    off = i*rs_w
    v = struct.unpack_from('<IIIIffff', rd_w, off)
    area_id = v[2]
    map_id = v[1]
    if area_id == 0:
        continue
    if map_id not in (0,1):
        continue
    # skip instances? MapID 0,1 are continents only, but some entries like 189 are instances (skip map 189 already filtered)
    name = id_to_name.get(area_id, "")
    if not name:
        # try fallback to WMA string
        name = gstr(st_w, v[3])
        print(f"fallback name for Area {area_id} -> '{name}'")
    if not name:
        continue
    # compute center
    L, R, T, B = v[4], v[5], v[6], v[7]
    # WMA stores Left, Right, Top, Bottom as world coords where Left > Right? Let's check.
    # Use absolute width
    # According to earlier analysis: L is left (west) positive large, R is right (east) negative, so width = L - R
    # Similarly height = T - B
    cx = (L + R) / 2.0
    cy = (T + B) / 2.0
    # continent bounds
    cL, cR, cT, cB = bounds[map_id]
    contW = cL - cR
    contH = cT - cB
    # normalized: (cL - cx)/contW , (cT - cy)/contH
    x = (cL - cx) / contW
    y = (cT - cy) / contH
    # cont mapping: prompt wants cont 1=Kalm, 2=EK but DBC Map 0=Azeroth(EK), 1=Kalimdor
    # Convert: cont = 1 if MapID==1 else 2
    cont = 1 if map_id == 1 else 2
    zones.append((name, area_id, map_id, cont, x, y, L, R, T, B))

# Sort by cont then name
zones_sorted = sorted(zones, key=lambda z: (z[3], z[0]))
for z in zones_sorted:
    name, area_id, map_id, cont, x, y, L,R,T,B = z
    print(f"{name:25} Area{area_id:4} Map{map_id} cont{cont} x={x:.3f} y={y:.3f}")

# Expected list from prompt - check missing
expected = ["Teldrassil","Darkshore","Moonglade","Winterspring","Felwood","Azshara","Ashenvale","Stonetalon Mountains","Durotar","Mulgore","The Barrens","Dustwallow Marsh","Desolace","Thousand Needles","Feralas","Tanaris","Un'Goro Crater","Silithus","Darnassus","Thunder Bluff","Orgrimmar",
"Tirisfal Glades","Western Plaguelands","Eastern Plaguelands","Hillsbrad Foothills","Alterac Mountains","Silverpine Forest","The Hinterlands","Arathi Highlands","Wetlands","Loch Modan","Dun Morogh","Badlands","Searing Gorge","Burning Steppes","Redridge Mountains","Elwynn Forest","Westfall","Duskwood","Deadwind Pass","Swamp of Sorrows","Stranglethorn Vale","Blasted Lands","Ironforge","Stormwind City","Undercity"]  # plus Gilneas etc not in vanilla DBC

print("\nMissing expected:")
for exp in expected:
    found = any(z[0]==exp for z in zones)
    if not found:
        print(f"  MISSING {exp}")

# Also check turtle customs expected: Alah'Thalas, Hyjal, Gillijim's Isle, Lapidis Isle, Tel'Abim, Tol Barad, Gilneas
turtle_expected = ["Alah'Thalas","Hyjal","Gillijim's Isle","Lapidis Isle","Tel'Abim","Tol Barad","Gilneas"]
for exp in turtle_expected:
    found = any(z[0]==exp for z in zones)
    print(f"Turtle {exp}: {'FOUND' if found else 'MISSING'}")

# Load old manual file for comparison
manual_path = pathlib.Path(r"C:\Users\rodri\OneDrive\wow\turtle wow\Interface\AddOns\ConsoleModeVanilla\Data\ZonePositions.lua")
if manual_path.exists():
    print("\nManual file exists, content preview:")
    print(manual_path.read_text(encoding='utf-8')[:800])
