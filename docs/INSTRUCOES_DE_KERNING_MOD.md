# Instruções de Ajuste de Espaçamento / Kerning em Fontes TrueType (TTF) para WoW 1.12

Este documento descreve a motivação técnica, a metodologia e o script automatizado utilizado para calibrar o espaçamento horizontal (*tracking / advance width / kerning*) de fontes TrueType diretamente no binário `.ttf`, contornando limitações do motor gráfico do World of Warcraft 1.12 (Vanilla).

---

## 1. Terminologia: Kerning vs. Tracking

- **Kerning:** Ajuste contextual fino entre pares específicos de letras (ex: aproximar o `o` do `T` na palavra `Total` para eliminar o vazio sob a haste do `T`). Fontes modernas utilizam tabelas OpenType `GPOS` para isso.
- **Tracking / Character Spacing:** Ajuste proporcional uniforme aplicado a todos os caracteres de uma fonte para torná-la globalmente mais aberta ou mais compacta.
- **Advance Width (`hmtx`):** No formato TrueType, cada caractere possui um valor numérico (`advanceWidth`) que informa ao motor gráfico quantos pixels o cursor deve avançar antes de desenhar a próxima letra.

No contexto deste mod, o ajuste efetuado altera o **Advance Width** global da fonte, produzindo um efeito visual de **tracking/kerning reduzido** diretamente no motor de texto do jogo.

---

## 2. O Problema no WoW 1.12 (FreeType Antigo)

1. **Incompatibilidade com OpenType `GPOS`:**
   - O WoW Vanilla utiliza uma versão do FreeType do início dos anos 2000.
   - Ele **não lê tabelas modernas `GPOS`**, onde ficam os pares de kerning modernos.
   - Ele só lia a tabela legada TrueType `kern` (formato 0 dos anos 90). Fontes modernas não trazem mais essa tabela legada.
   - Sem o `GPOS`, o WoW posiciona cada letra baseando-se estritamente na largura bruta de avanço (`advanceWidth`) da tabela `hmtx`. O resultado é que fontes modernas aparentam estar "esticadas" ou com letras muito separadas.

2. **Ausência de API Lua no WoW 1.12:**
   - O método `FontString:SetSpacing(n)` do WoW 1.12 controla apenas o espaçamento vertical entre linhas de textos multilinha; **não existe API Lua no jogo para letter-spacing horizontal**.

3. **A Solução:**
   - Modificar os bytes da tabela `hmtx` diretamente no arquivo `.ttf`, reduzindo o `advanceWidth` de todos os glifos proporcionalmente.

---

## 3. Histórico de Calibração no Steam Deck (1280x800)

Durante os testes na barra de abas superiores do `ConsoleModeVanilla` com a fonte **Alegreya Sans Bold** em tamanho **19px**:

| Redução | Fator Multiplicador | Resultado Visual |
| :--- | :--- | :--- |
| **0% (Original)** | `1.00` | Letras muito abertas/esticadas, sensação de texto desconexo. |
| **-15%** | `0.85` | Excessivamente compacto; letras com hastes verticais encostaram umas nas outras. |
| **-5%** | `0.95` | Melhorou substancialmente e eliminou colisões, mas ainda havia uma folga desnecessária. |
| **-9% (Sweet Spot)** | **`0.91`** | **Equilíbrio perfeito.** Visual moderno de interface de console (estilo SteamOS/Xbox), letras próximas e sem nenhuma colisão de traços. |

---

## 4. Script Python de Automação (Sem dependências externas)

O script abaixo utiliza apenas módulos padrão do Python (`struct` e `os`). Ele pode ser executado diretamente em qualquer máquina Linux ou no terminal do Steam Deck.

```python
#!/usr/bin/env python3
import struct
import sys
import os

def calc_table_checksum(data):
    """Calcula o checksum de 32 bits de uma tabela TrueType."""
    rem = len(data) % 4
    if rem:
        data = data + b'\x00' * (4 - rem)
    n = len(data) // 4
    return sum(struct.unpack(f'>{n}I', data)) & 0xFFFFFFFF

def adjust_ttf_advance_width(input_path, output_path, factor=0.91):
    """
    Ajusta a largura de avanço (advanceWidth) de todos os glifos na tabela hmtx.
    factor = 0.91 aplica -9% de espaçamento.
    """
    if not os.path.exists(input_path):
        print(f"Erro: Arquivo {input_path} nao encontrado.")
        return False

    with open(input_path, 'rb') as f:
        data = bytearray(f.read())

    # Leitura do cabeçalho de tabelas TrueType
    num_tables = struct.unpack('>H', data[4:6])[0]
    tables = {}
    table_entries = {}
    for i in range(num_tables):
        entry_pos = 12 + i * 16
        tag, check, off, length = struct.unpack('>4sIII', data[entry_pos:entry_pos+16])
        tname = tag.decode('latin1')
        tables[tname] = (off, length)
        table_entries[tname] = entry_pos

    if 'hmtx' not in tables or 'hhea' not in tables or 'head' not in tables:
        print("Erro: Font TTF invalida (tabelas hmtx/hhea/head ausentes).")
        return False

    hhea_off, _ = tables['hhea']
    numOfLongHorMetrics = struct.unpack('>H', data[hhea_off+34:hhea_off+36])[0]
    hmtx_off, hmtx_len = tables['hmtx']
    head_off, _ = tables['head']

    # Modifica o advanceWidth de cada glifo na tabela hmtx
    for g in range(numOfLongHorMetrics):
        pos = hmtx_off + g * 4
        orig_adv = struct.unpack('>H', data[pos:pos+2])[0]
        new_adv = int(round(orig_adv * factor))
        struct.pack_into('>H', data, pos, new_adv)

    # Recalcula o checksum da tabela hmtx no Table Directory
    new_hmtx_checksum = calc_table_checksum(data[hmtx_off:hmtx_off+hmtx_len])
    struct.pack_into('>I', data, table_entries['hmtx']+4, new_hmtx_checksum)

    # Recalcula o checkSumAdjustment da tabela head
    struct.pack_into('>I', data, head_off+8, 0)
    total_check = calc_table_checksum(data)
    new_csa = (0xB1B0AFBA - total_check) & 0xFFFFFFFF
    struct.pack_into('>I', data, head_off+8, new_csa)

    with open(output_path, 'wb') as f:
        f.write(data)

    print(f"Sucesso! Fonte salva em: {output_path} (Fator: {factor})")
    return True

if __name__ == '__main__':
    # Exemplo de uso:
    # python3 adjust_ttf.py Media/Fonts/AlegreyaSans-Bold.ttf Media/Fonts/AlegreyaSans-Bold.ttf 0.91
    input_file = sys.argv[1] if len(sys.argv) > 1 else 'Media/Fonts/AlegreyaSans-Bold.ttf'
    output_file = sys.argv[2] if len(sys.argv) > 2 else input_file
    factor_val = float(sys.argv[3]) if len(sys.argv) > 3 else 0.91

    adjust_ttf_advance_width(input_file, output_file, factor_val)
```

---

## 5. Dicas e Boas Práticas no WoW 1.12

1. **Reindexação no Disco:**
   - O executável do WoW 1.12 indexa os nomes de arquivos existentes na pasta `Interface/` **apenas no momento em que o jogo inicia**.
   - Se um arquivo `.ttf` for criado com um nome inédito enquanto o jogo estiver aberto, o `/reload` não o encontrará.
   - Ao modificar o arquivo `.ttf` existente com o mesmo nome, um reinício rápido (**`STEAM` + `B`** e depois **`A`** no Steam Deck) garante que o FreeType descarte o cache de memória e leia as novas métricas do binário.

2. **Compatibilidade com Acentos (PT-BR):**
   - Fontes utilizadas no WoW 1.12 com clientes que usam codificação ocidental exigem a sub-tabela `cmap` com **Platform 1, Encoding 0 (Mac Roman)** ou formato 0/6.
   - A família **Alegreya Sans** já traz essa tabela de fábrica com todos os caracteres acentuados (`ã`, `õ`, `ç`, `é`, `í`, etc.) mapeados perfeitamente.

3. **Licenciamento (Importante):**
   - Fontes proprietárias (como a *Motiva Sans* da Valve/Plau) possuem licenças restritas e **não podem** ser redistribuídas em repositórios públicos de addons.
   - A **Alegreya Sans** está sob licença **SIL Open Font License (OFL)**, sendo 100% livre para modificação, empacotamento e redistribuição gratuita.
