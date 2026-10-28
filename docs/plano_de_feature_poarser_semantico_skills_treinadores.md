# Plano Resumido: Parser Semântico de Evolução de Skills & Correções Visuais no Menu de Treinadores

> **Objetivo:** Corrigir os detalhes visuais do painel comparativo de evolução de habilidades em `UI/TrainerMenu.lua` e implementar o **Parser Semântico de Diferenças (Deltas)** entre o grau atual no Grimório e o novo grau oferecido pelo treinador.

---

## 1. Diagnóstico do Estado Atual

1. **Seta Unicode Invisível no Badge de Evolução (`TRAINER_BADGE_EVOLUTION_FMT`):**
   - A chave `TRAINER_BADGE_EVOLUTION_FMT` usa o caractere Unicode `➔` (`U+2794`), que não existe na fonte `AlegreyaSans-Bold.ttf` / `FRIZQT__.TTF` do cliente WoW 1.12.1, fazendo com que apareça um espaço em branco `(Grau 1  Grau 2)` em vez de `(Grau 1 -> Grau 2)`.
2. **Ausência da Linha de Atributos Operacionais no Card do Grimório (`[ATUALMENTE NO GRIMÓRIO]`):**
   - `TrainerMenu:ScanSpellbook()` ignorava as linhas de cabeçalho operacional (`Mana/Fúria/Energia`, `Alcance`, `Tempo de Lançamento`, `Recarga`), exibindo a linha azul apenas no card `[NOVO GRAU]` e impossibilitando comparar o custo de recurso entre os dois graus.
3. **Parser de Deltas Desativado (`ComputeDiffLines`):**
   - A versão antiga extraía números soltos pela posição na frase, confundindo duração (`30 s -> 35 s`) com dano. Por isso estava desconectada do card inferior.

---

## 2. Escopo da Implementação

### Etapa 1 — Correção da Seta de Evolução e Cabeçalho Operacional do Grimório
- Substituir `➔` por `->` em `TRAINER_BADGE_EVOLUTION_FMT` e `TRAINER_DIFF_LINE_FMT` nos dicionários `enUS` e `ptBR`.
- Atualizar `TrainerMenu:ScanSpellbook()` para extrair `stats` (Custo, Alcance, Lançamento, Recarga), `costVal` / `costType` e `tools` do feitiço atual no Grimório, usando os mesmos filtros estritos de `GetTrainerServiceTooltipData`.
- Exibir o cabeçalho operacional azul (`|cff88ccff...`) também no topo do card `[ATUALMENTE NO GRIMÓRIO]`.

### Etapa 2 — Parser Semântico de Deltas (`TrainerMenu:ComputeSemanticDiffs`)
Implementar extração contextual bilíngue (`ptBR` e `enUS`) que só emite linhas quando há diferença real (`old ~= new`):
- **Dano em Faixa (Range):** ex. `9 a 11 de dano` vs `13 a 17 de dano` ➔ `• Dano: 9-11 -> 13-17 (+4 a +6)`
- **Cura em Faixa (Range):** ex. `40 a 50` vs `75 a 90` ➔ `• Cura: 40-50 -> 75-90 (+35 a +40)`
- **Dano / Cura / Armadura / Atributo Fixo:** captura contextual por sentença sem confundir com duração ou alcance ➔ `• Dano: 20 -> 35 (+15)` / `• Armadura: 120 -> 180 (+60)`
- **Duração (`por X s`, `ao longo de X s`, `for X sec`, `over X sec`, `X min`):** ➔ `• Duração: 30s -> 35s (+5s)`
- **Custo de Recurso (`Mana`, `Fúria`, `Energia`):** compara o custo do grau atual no Grimório com o novo grau no treinador ➔ `• Custo: 25 -> 45 de Mana (+20)`

### Etapa 3 — Integração Visual no Card Inferior (`ShowServiceDetail`)
- No modo **Upgrade / Evolução de Grau**, exibir no card inferior os deltas semânticos em destaque verde/amarelo ao lado do resumo financeiro e requisitos de nível/ferramenta, ajustando a altura dos cards para zero sobreposição de texto.
- Validar todos os arquivos modificados com `luac50.exe -p`.
