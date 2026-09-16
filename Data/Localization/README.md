# ConsoleMode - Vanilla: Localization System / Sistema de Localização

---

## English

### Status: Under Active Development & Continuous Refinement

The ConsoleModeVanilla localization system is currently **under active construction and continuous architectural expansion**. Rather than a static set of strings, the addon features an integrated **Contextual Game Translation Engine (GamePT)** designed specifically for World of Warcraft 1.12.1 (strict Lua 5.0) and Turtle WoW 1.17.2 content.

External guides for creating community translations are temporarily paused while the core architecture, data pipelines, and contextual engines are being stabilized and refined.

### Architecture Overview

1. **Modular UI Strings (`Data/Localization/`):**
   - Base language: Brazilian Portuguese (`ptBR`), with full runtime fallback and live switching via `/cm lang`.
   - International interface: English (`enUS`) with 100% strict key parity maintained by automated tooling (`tools/check_locales.py`).
   - Flat key-value architecture (`CM_Langs[lang].strings`) with zero runtime overhead.

2. **GamePT Contextual Engine (`Data/Localization.lua`):**
   - **Skills & Proficiencies (`CM:GamePT_Skill`):** Weapon skills, armor proficiencies, primary & secondary professions, and racial languages.
   - **Ranks (`CM:GamePT_Rank`):** Automatic normalization of rank strings (*Rank X* → *Grau X*, *Passive* → *Passiva*).
   - **Talent Names (`CM:GamePT_Talent`):** Contextual naming for all 460 unique talents across all 9 classes, supporting both coordinate lookups and name matching.
   - **Dynamic Talent Descriptions (`Data/TalentDescriptions_ptBR.lua`):** Real-time template engine with `%s` injection. Numbers (damage, cooldowns, proc chances, durations) are extracted directly from the native game client tooltip and injected live into curated Blizzard-standard translations.
   - **Talent Inspect & Comparison Modal:** In-game side-by-side inspection view (`[A]` on talent trees) displaying translated and original descriptions simultaneously for debugging and readability.
   - **Spells & Buffs (`CM:GamePT_Spell`, `CM:GamePT_Buff`):** High-efficiency lookups for action bars, pickers, and HUD elements.
   - **Integrated Quest Database (`Data/QuestDB_ptBR.lua`):** Embedded offline database of 6,600+ quests covering Vanilla 1.12 and Turtle WoW custom content.

3. **Validation & Quality Assurance:**
   - Automated locale verification script: `python3 tools/check_locales.py` ensuring strict parity across UI keys, cataloged talents, templates, and exceptions.
   - Strict Lua 5.0 compilation check: `luac -p` on all data files to guarantee 1.12.1 client compatibility without modern Lua operators (`#`, `continue`, etc.).

---

## Português

### Status: Em Desenvolvimento Ativo e Contínuo Aprimoramento

O sistema de localização do ConsoleModeVanilla está atualmente **em construção ativa e aprimoramento contínuo de sua arquitetura**. Mais do que uma lista estática de textos, o addon conta com um **Motor de Tradução Contextual de Jogo (GamePT)** projetado especificamente para o cliente World of Warcraft 1.12.1 (Lua 5.0 estrito) e os conteúdos do Turtle WoW 1.17.2.

O guia aberto de criação de novas traduções externas foi retirado temporariamente enquanto os alicerces do motor, os pipelines de dados e a fidelidade de tradução estão sendo consolidados pelo projeto.

### Visão Geral da Arquitetura

1. **Strings Modulares de Interface (`Data/Localization/`):**
   - Idioma base: Português do Brasil (`ptBR`), com fallback completo e troca dinâmica em runtime via `/cm lang`.
   - Interface internacional: Inglês (`enUS`) mantendo 100% de paridade estrita de chaves através de validação automatizada (`tools/check_locales.py`).
   - Estrutura plana de chaves (`CM_Langs[lang].strings`) garantindo performance nativa sem gargalos de memória.

2. **Motor Contextual GamePT (`Data/Localization.lua`):**
   - **Perícias e Profissões (`CM:GamePT_Skill`):** Armas, armaduras, profissões primárias/secundárias e idiomas raciais traduzidos na tela de personagem.
   - **Graus e Ranks (`CM:GamePT_Rank`):** Normalização contextual de ranks (*Rank X* → *Grau X*, *Passive* → *Passiva*).
   - **Nomes de Talentos (`CM:GamePT_Talent`):** Catálogo de todos os 460 talentos únicos das 9 classes, com suporte a coordenadas da árvore e busca por nome canônico.
   - **Descrições Dinâmicas de Talentos (`Data/TalentDescriptions_ptBR.lua`):** Motor de templates com injeção de `%s`. Todos os números (dano, recarga, chance de ativação, duração) são extraídos ao vivo do tooltip do próprio cliente do jogo e inseridos nos templates traduzidos no padrão Blizzard pt-BR.
   - **Modal de Inspeção e Comparação de Talentos:** Tela interativa lado a lado (`[A]` nas árvores de talentos) permitindo visualizar o texto traduzido e a descrição original em inglês para checagem de fidelidade e máxima legibilidade.
   - **Magias e Buffs (`CM:GamePT_Spell`, `CM:GamePT_Buff`):** Resolução rápida para barras de ação, seletores visuais e HUD.
   - **Banco de Missões Integrado (`Data/QuestDB_ptBR.lua`):** Base de dados com mais de 6.600 missões integradas cobrindo tanto o conteúdo clássico 1.12 quanto as novidades do Turtle WoW.

3. **Garantia de Qualidade e Validação:**
   - Validador automatizado: `python3 tools/check_locales.py` garantindo paridade absoluta de chaves de UI, talentos catalogados, templates e exceções.
   - Checagem estrita de sintaxe: `luac -p` em todos os arquivos de dados para assegurar compatibilidade absoluta com o motor Lua 5.0 do cliente 1.12.1.