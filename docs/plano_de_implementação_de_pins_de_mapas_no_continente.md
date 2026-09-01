# Plano de Implementação: Pins de Mapas no Continente (ZonePositions Autoritativo via DBC)

> [!IMPORTANT]
> **REGRAS MANDATÓRIAS DE DESENVOLVIMENTO:**
> 1. **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Turtle WoW).
> 2. **Versão do Lua:** Lua 5.0 (FrameXML clássico). Proibido usar operadores de Lua 5.1+ (como `#table`, usar `table.getn(t)` ou `getn(t)`).
> 3. **Validação de Sintaxe:** Todo arquivo `.lua` criado ou alterado deve ser validado via `luac -p` antes de qualquer teste.
> 4. **Regra Crítica de Commit:** NUNCA fazer commit ou push sem o comando e autorização explícita do usuário.
> 5. **Regra de Parada Crítica de Fases:** NUNCA avançar para a fase seguinte sem `/reload` e validação do usuário.

---

## 1. Visão Geral

O sistema de pins no **CONTINENTE** (`KALIMDOR` / `EASTERN KINGDOMS`) exibe zona por zona ao fazer hover em `REGIÕES` (ou navegar via D-Pad) um pin amarelo + label posicionado sobre o mapa do continente (`mapCanvas.zonePin` dentro de `mapTilesContainer`). As coordenadas estavam **esticadas/fora do contorno** porque `Data/ZonePositions.lua` foi criado manualmente no commit `71a7193` (WIP, valores `x=0.345`-`0.735` chutados visualmente). Pins dentro de **ZONA** (NPCs via `pfDB.units.coords`) são perfeitos pois usam `x/100 * effW`; o erro era só no continente.

Solução: gerar `ZonePositions` 100% autoritativo extraindo `WorldMapArea.dbc` + `AreaTable.dbc` do MPQ do cliente, convertendo coordenadas de mundo (yard) para 0-1 do continente 1002×668.

---

## 2. Diagnóstico

* `pfQuest/db/minimap.lua` contém `pfDB["minimap"][zoneID] = {worldSizeX, worldSizeY}` — só tamanho, não posição.
* `pfQuest/db/zones.lua` contém `pfDB["zones"]["data"][id] = {parentZone, x1,y1,x2,y2}` — áreas de sub-zona, não `cont/x/y`.
* Nenhum arquivo `pfQuest` contém `cont/x=0.`/`y=0.` para continente — busca com `rg "ZonePositions|x = 0\."` retornou vazio.
* `Data/ZonePositions.lua` era portanto a única fonte e estava incorreta. Exemplos do erro:
  * `Azshara` manual `0.735,0.295` → DBC `0.622,0.373` (leste demais no manual)
  * `Stonetalon Mountains` manual `0.345,0.485` → DBC `0.442,0.469`
  * `Ashenvale` manual `0.415,0.395` → DBC `0.496,0.410`
* Motor de pin: `UI/MainMenu.lua:UpdateZonePinPosition` usa `effW/effH = tilesContainer:GetWidth/Height` (fallback `1002*scale` / `668*scale`) e `SetPoint("CENTER", container, "TOPLEFT", pos.x*effW, -pos.y*effH)`. Se `pos` errado, pin deslocado mesmo com palco correto.

---

## 3. Arquitetura do MPQ/DBC (Vanilla 1.12)

```
C:\Users\rodri\OneDrive\wow\turtle wow\Data\
  dbc.MPQ          → DBFilesClient\WorldMapArea.dbc (50 recs) + AreaTable.dbc (988 recs)  (vanilla)
  patch.MPQ        → DBFilesClient\WorldMapArea.dbc (51 recs) + AreaTable.dbc (1081 recs) (Turtle, mais recente)
  Patch-T.mpq etc  → Turtle customs (sem WorldMapArea)
```

### 3.1 Formato WDBC

* Header 20 bytes: `magic 'WDBC' (4s), records (I), fields (I), record_size (I), string_size (I)` (`<4sIIII`, little-endian).
* `WorldMapArea.dbc`: 8 campos, 32 bytes por registro: `ID, MapID, AreaID, NameOff, LocLeft, LocRight, LocTop, LocBottom` (`<IIIIffff`). `NameOff` é offset no bloco de strings (ex: `StonetalonMountains`), mas o nome canônico vem de `AreaTable`.
* `AreaTable.dbc` (patch): 25 campos, 100 bytes. Campo **11** (índice 11) é offset `enUS` do nome localizado (ex: `Stonetalon Mountains`, `Dustwallow Marsh`). Outros locales nos campos vizinhos.
* `WorldMapContinent.dbc`: 2 registros (Map 0 Azeroth, Map 1 Kalimdor) — não usado diretamente; bounds pegos de `WorldMapArea` onde `AreaID==0`.

### 3.2 Coordenadas

* `MapID`: `0 = Azeroth (EK)`, `1 = Kalimdor` (Turtle mantém).
* Continente vanilla: `Kalimdor L17066.6 R-19733.2 T12799.9 B-11733.3` (width `36799.8`, height `24533.2`); `Azeroth L16000 R-19199.9 T7466.6 B-16000` (width `35199.9`, height `23466.6`).
* Zona ex: `Teldrassil L3814.6 R-1277.1 T11831.2 B8437.5` → centro `cx=(L+R)/2=1268.7`, `cy=10134.3`.
* Normalização: `x=(cL - cx)/(cL - cR)`, `y=(cT - cy)/(cT - cB)` — `cL` é Left do continente (maior valor), `cR` o Right (negativo). Resultado 0-1 direto para `1002×668` (sem palco adicional).

---

## 4. Passo a Passo Reprodutível

### Passo 1 — Localizar MPQs

```powershell
Get-ChildItem "C:\Users\rodri\OneDrive\wow\turtle wow\Data\*.MPQ"
# usar dbc.MPQ e patch.MPQ (patch é mais recente e contém Silithus corrigido: L2537 vs 4641 antigo)
```

### Passo 2 — Instalar dependência

```powershell
pip install mpyq
python3 -c "import mpyq; print(mpyq.__file__)"
```

Limitação: `Patch-W.mpq` é criptografado (`Encryption is not supported yet`) — ignorar, não contém `WorldMapArea`.

### Passo 3 — Extrair DBCs

```powershell
python3 -c "
import mpyq, pathlib
tmpdir = pathlib.Path(r'C:\Users\rodri\AppData\Local\Temp\opencode')
for mpq in [pathlib.Path(r'C:\Users\rodri\OneDrive\wow\turtle wow\Data\dbc.MPQ'),
            pathlib.Path(r'C:\Users\rodri\OneDrive\wow\turtle wow\Data\patch.MPQ')]:
    arc = mpyq.MPQArchive(str(mpq))
    for dbc in ['DBFilesClient\\WorldMapArea.dbc','DBFilesClient\\AreaTable.dbc']:
        data = arc.read_file(dbc)
        out = tmpdir / f'{mpq.stem}_{dbc.split(chr(92))[-1]}'
        out.write_bytes(data)
        print(out, len(data))
"
# Saída esperada:
# dbc_WorldMapArea.dbc 2154, dbc_AreaTable.dbc 97455
# patch_WorldMapArea.dbc 2208, patch_AreaTable.dbc 123958
```

Alternativa: listar via `arc.files` (140 entradas) e `arc.read_file('(listfile)')`.

### Passo 4 — Inspecionar estrutura

```python
import struct, pathlib
def load(path):
    d=path.read_bytes()
    magic,recs,fields,rs,ss=struct.unpack_from('<4sIIII', d, 0)
    return recs,fields,rs,d[20:20+recs*rs],d[20+recs*rs:]
recs,fields,rs,rd,st = load(pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode\patch_WorldMapArea.dbc"))
# recs=51 fields=8 rs=32
for i in range(recs):
    ID,Map,Area,NameOff,L,R,T,B = struct.unpack_from('<IIIIffff', rd, i*rs)
    print(f"{ID} Map{Map} Area{Area} L{L:.1f} R{R:.1f} T{T:.1f} B{B:.1f}")
```

### Passo 5 — Mapear AreaID → Nome localizado

```python
import struct, pathlib
def gstr(st, off):
    j=st.find(b'\x00', off)
    return st[off:j].decode('utf-8', errors='ignore')
recs,fields,rs,rd,st = load(pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode\patch_AreaTable.dbc"))
# fields=25, rs=100, campo 11 = enUS
id_to_name={}
for i in range(recs):
    vals=struct.unpack_from('<'+'I'*fields, rd, i*rs)
    name=gstr(st, vals[11])
    if name: id_to_name[vals[0]] = name
# teste: 406→Stonetalon Mountains, 15→Dustwallow Marsh, 331→Ashenvale
```

### Passo 6 — Calcular posições

```python
# bounds dos continentes (AreaID==0)
bounds={}
for i in range(recs_wma):
    ID,Map,Area,NameOff,L,R,T,B = struct.unpack_from('<IIIIffff', rd_wma, i*rs_wma)
    if Area==0:
        bounds[Map]=(L,R,T,B)  # 1=Kalimdor, 0=Azeroth

zones=[]
for i in range(recs_wma):
    ID,Map,Area,NameOff,L,R,T,B = struct.unpack_from('<IIIIffff', rd_wma, i*rs_wma)
    if Area==0 or Map not in (0,1): continue
    name=id_to_name.get(Area) or gstr(st_wma, NameOff)
    cx=(L+R)/2; cy=(T+B)/2
    cL,cR,cT,cB=bounds[Map]
    x=(cL-cx)/(cL-cR); y=(cT-cy)/(cT-cB)
    cont=1 if Map==1 else 2
    zones.append((name,cont,x,y))
# ordenar por cont/nome
zones=sorted(zones, key=lambda z:(z[1],z[0]))
```

### Passo 7 — Turtle customs (sem WorldMapArea)

7 zonas não têm entrada em `WorldMapArea.dbc` (não estão em Map 0/1):
`Alah'Thalas (1,0.55,0.35)`, `Hyjal (1,0.52,0.34)`, `Gillijim's Isle (1,0.68,0.90)`, `Lapidis Isle (2,0.72,0.92)`, `Tel'Abim (2,0.38,0.92)`, `Gilneas (2,0.30,0.38)`, `Tol Barad (2,0.32,0.60)` — manter valores manuais com comentário `-- Turtle custom: aproximado (sem WorldMapArea.dbc)`.

### Passo 8 — Gerar `Data/ZonePositions.lua`

```python
out=["ConsoleMode = ConsoleMode or {}", "ConsoleMode.ZonePositions = {"]
for name,cont,x,y in zones:  # 46 vanilla + cidades (Darnassus etc)
    out.append(f'    ["{name}"] = {{ cont = {cont}, x = {x:.3f}, y = {y:.3f} }},')
for name,cont,x,y in turtle_customs:
    out.append(f'    ["{name}"] = {{ cont = {cont}, x = {x:.3f}, y = {y:.3f} }}, -- Turtle custom: aproximado (sem WorldMapArea.dbc)')
out.append("}")
pathlib.Path(r"C:\Users\rodri\OneDrive\wow\turtle wow\Interface\AddOns\ConsoleModeVanilla\Data\ZonePositions.lua").write_text("\n".join(out)+"\n", encoding='utf-8')
```

Arquivo final tem 53 entradas (21 Kalimdor + 25 EK + 7 Turtle). Ordem alfabética por continente facilita diff. Exemplo de saída (confirmada):

```
["Teldrassil"] = { cont = 1, x = 0.429, y = 0.109 },
["Ashenvale"] = { cont = 1, x = 0.496, y = 0.410 },
["Silithus"] = { cont = 1, x = 0.442, y = 0.812 }, -- corrigido vs dbc antigo 0.285,0.865
["Tirisfal Glades"] = { cont = 2, x = 0.433, y = 0.219 },
...
```

### Passo 9 — Validar sintaxe (Lua 5.0)

```powershell
luac -p "C:\Users\rodri\OneDrive\wow\turtle wow\Interface\AddOns\ConsoleModeVanilla\Data\ZonePositions.lua" ; echo "OK"
luac -p "C:\Users\rodri\OneDrive\wow\turtle wow\Interface\AddOns\ConsoleModeVanilla\UI\MainMenu.lua" ; echo "OK"
# sem `#table`, sem `...`, usar `table.getn` se necessário
```

### Passo 10 — Teste in-game

1. `/reload`
2. `QUESTS` → mapa → `KALIMDOR` / `EASTERN KINGDOMS` (botões verticais `ATUAL/KALIMDOR/EASTERN`, sem duplo clique — fix `NavToContinent` com `mapFileName` explícito `Kalimdor`/`Azeroth` + `UpdateMapTextures` forçado).
3. Hover `REGIÕES` ou D-Pad entre zonas — pin amarelo deve cair dentro do contorno/label (comparar `Azshara 0.622` leste, `Desolace 0.410` oeste, `Silithus` sul).
4. `tools/extract_zone_positions.py` deixado em `tools/` para re-extrair se `patch.MPQ` atualizar.

### Passo 11 — Não fazer commit sem autorização

```powershell
git status  # deve mostrar apenas Data/ZonePositions.lua modificado (+ tools/ untracked)
# aguardar pedido explícito do usuário para `git add && git commit`
```

---

## 5. Scripts de Referência

* `C:\Users\rodri\AppData\Local\Temp\opencode\parse_wma.py` — dump de `WorldMapArea` com `L/R/T/B`.
* `C:\Users\rodri\AppData\Local\Temp\opencode\find_string.py` — localiza `Stonetalon`/`Dustwallow` em `AreaTable` e confirma campo 11.
* `C:\Users\rodri\AppData\Local\Temp\opencode\generate_zonepositions.py` — pipeline completo (load → bounds → calc → print).
* `C:\Users\rodri\AppData\Local\Temp\opencode\gen_final.py` — gera `ZonePositions.lua` final e copia para `tools/extract_zone_positions.py`.
* `tools/extract_zone_positions.py` (dentro do addon) — versão commitável do pipeline.

---

## 6. Armadilhas e Notas

* **Não usar `dbc.MPQ` sozinho**: Silithus e algumas bounds estão desatualizados vs `patch.MPQ` (Turtle corrige). Sempre preferir `patch.MPQ` quando existir registro duplicado.
* **`MapID` vs `cont`**: DBC usa `0=Azeroth`, `1=Kalimdor`; addon usa `cont 1=Kalimdor`, `2=EK` (`cont = 1 if Map==1 else 2`). Inverter causa pins trocados de continente.
* **Left > Right**: `L` é oeste (positivo), `R` é leste (negativo) — width = `L - R`, não `R - L`. Usar `abs` quebra.
* **Palco**: `UpdateZonePinPosition:5238` já usa `tilesContainer:GetWidth/Height` (1002×668 escalado por `currentScale`). Não reintroduzir `MapPalco` com `xScale/yScale` — foi revertido por esticar.
* **Turtle sem DBC**: customs nunca aparecerão em `WorldMapArea`; manter fallback manual ou, futuro, extrair `WorldMapOverlay.dbc` ou medir via `BLP` do mapa (método imagem) se Turtle publicar novas coordenadas.

---

## 7. Como Repetir no Futuro

1. Atualizou `patch.MPQ`? Re-extrair `patch_WorldMapArea.dbc` e `patch_AreaTable.dbc` (Passo 3).
2. Rodar `tools/extract_zone_positions.py` (ou `gen_final.py`) — gera novo `ZonePositions.lua`.
3. `luac -p` → `/reload` → teste hover em `CONTINENT`.
4. Se nova zona Turtle aparecer (ex: `NewZone`), checar se `AreaID` existe em `AreaTable` mas não em `WorldMapArea` → adicionar manualmente após medir na textura `Interface\WorldMap\...` ou aguardar Turtle publicar DBC.

---

*Gerado em 2026-09-01 — extração via `mpyq` + `struct` Python, Lua 5.0, Turtle WoW 1.12. Método DBC autoritativo substitui chute manual.*
