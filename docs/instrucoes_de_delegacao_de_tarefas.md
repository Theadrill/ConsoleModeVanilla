# Instruções de Delegação de Tarefas de Código (Antigravity ➔ OpenCode / Orca)
### Projeto: ConsoleModeVanilla (WoW Vanilla 1.12.1 / Turtle WoW / Lua 5.0)

> [!CAUTION]
> # 🛑 REGRA ZERO (ABSOLUTA E MANDATÓRIA): PROIBIÇÃO DE COMMIT/PUSH & PARADA CRÍTICA
> **ESTA É A REGRA MAIS IMPORTANTE DE TODO O PROJETO. NENHUM MODELO (ANTIGRAVITY OU OPENCODE) PODE VIOLAR:**
> 1. **NUNCA FAÇA `git commit` OU `git push` SOB HIPÓTESE ALGUMA POR CONTA PRÓPRIA.**
> 2. Qualquer tentativa de commit ou push sem ordem explícita é uma **falha crítica de segurança operacional**.
> 3. O Antigravity e o OpenCode estão **TERMINANTEMENTE PROIBIDOS** de criar commits ou enviar código sem a ordem direta, textual e inequívoca do usuário.
> 4. Quando (e se) o usuário der a ordem explícita para push, o Antigravity executa o push **EXATAMENTE UMA VEZ** e aguarda nova instrução antes de qualquer outro comando git.
> 5. **PARADA CRÍTICA OBRIGATÓRIA A CADA PASSO:** Cada fase ou passo deve ser 100% autônomo e executável sem quebrar o addon. Ao concluir um passo, é OBRIGATÓRIO parar, solicitar a validação do usuário no jogo via `/reload` e **SÓ AVANÇAR** para o próximo passo quando o usuário validar e aprovar explicitamente!

---

Este documento especifica o procedimento padronizado para delegação sob demanda de tarefas de desenvolvimento do **Antigravity (Tech Lead / Orquestrador)** para o **OpenCode (Dev / Coder)** via Orca CLI ou Headless CLI.

---

## 🧠 1. Papel do Orquestrador (Economia Crítica de Tokens & Custos)

> [!IMPORTANT]
> **OBJETIVO FINANCEIRO & OPERACIONAL PRINCIPAL:**  
> Economizar tokens e reduzir drasticamente os custos com **output tokens no modelo pago** (Antigravity, Claude 3.5/3.7, etc.). O modelo pago atua estritamente como **Orquestrador / Tech Lead de alto nível** (gerando prompts curtos e concisos), enquanto o **modelo gratuito/local do OpenCode** assume o trabalho pesado de codificação, leitura de arquivos e geração de código extenso.

O fluxo de delegação para o **OpenCode** deve seguir as seguintes diretrizes para garantir essa economia:

1. **Delegação Enxuta e Objetiva:**
   - O Antigravity **NÃO DEVE** ler arquivos de código inteiros (como `MainMenu.lua` de 8.000 linhas) nem fazer varreduras exploratórias pesadas com grep no codebase antes de despachar.
   - O trabalho braçal de leitura aprofundada, busca em arquivos e implementação de código pertence exclusivamente ao **OpenCode**.
2. **Leitura Restrita ao Plano:**
   - O Antigravity deve ler unicamente o plano da etapa a ser executada (`docs/plano_de_feature_*.md`) e formular uma especificação técnica concisa no prompt da tarefa (o que fazer, arquivos-alvo, assinaturas e restrições).
3. **Foco em Coordenação, Revisão Técnica e QA:**
   - Despachar a tarefa com regras claras e contexto essencial.
   - Aguardar a conclusão via `worker_done` ou `tui-idle`.
   - Validar sintaxe via compilador Lua (`luac -p <arquivo.lua>`) e inspecionar superficialmente o diff (`git status`, `git diff --stat`).
   - Apresentar o resumo ao usuário e solicitar validação in-game com `/reload`.
   - *Tratamento de Falhas:* Se a sintaxe falhar ou a validação divergir do esperado, o Antigravity assume o diagnóstico pontual da causa raiz e repassa ao OpenCode a orientação de correção cirúrgica.
4. **Compaction Obrigatória Entre Etapas:**
   - Sempre que uma etapa ou fase terminar e formos iniciar outra no OpenCode, o orquestrador **DEVE** enviar o comando `/compact` para o terminal do OpenCode (e aguardar ficar ocioso via `tui-idle`) antes de despachar a nova demanda, evitando acúmulo desnecessário de contexto na sessão do coder.

---

## 📌 2. Passo 1: Seleção da Estratégia de Execução

Sempre que o usuário solicitar a delegação de uma tarefa (caso não tenha especificado a via no prompt), o **Antigravity** deve verificar se o usuário já indicou o modo de execução ou perguntar qual prefere:

1. **Opção A: Orca Orchestration (`orca-cli`) [Padrão / Recomendada]**
   - *Quando usar:* Quando desejar visibilidade nos terminais do Orca ADE, acompanhamento interativo de TUI, rastreamento formal de tarefas e eventos de ciclo de vida (`worker_done`, `heartbeat`).
2. **Opção B: OpenCode Direto (Headless CLI)**
   - *Quando usar:* Para execuções rápidas em background sem interface TUI.

---

## 📌 3. Passo 2: Execução Técnica via Orca Orchestration (`orca-cli`)

1. **Garantir/Vincular Run:**
   ```powershell
   orca orchestration run-create --objective "Descrição objetiva da tarefa" --json
   ```

2. **Obter, Verificar ou Iniciar Terminal do OpenCode & Aplicar `/compact`:**
   - O orquestrador **DEVE SEMPRE** tentar reaproveitar o terminal existente. Liste os terminais ativos:
     ```powershell
     orca terminal list --json
     ```
   - Localize o terminal com `agentIdentity: "opencode"` (ou título correspondente), recupere o seu `<handle>` e envie `/compact` para limpar o contexto anterior:
     ```powershell
     orca terminal send --terminal <handle> --text "/compact" --enter --json
     orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 20000 --json
     ```
   - *Apenas* se não houver terminal aplicável, crie um novo:
     ```powershell
     orca terminal create --worktree active --title "OpenCode" --command "opencode" --json
     orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 30000 --json
     ```

3. **Criar a Tarefa:**
   ```powershell
   orca orchestration task-create --spec "Instruções técnicas detalhadas com regras rígidas..." --json
   ```

4. **Despachar a Tarefa (com injeção de preâmbulo):**
   ```powershell
   orca orchestration dispatch --task <task_id> --to <handle> --inject --json
   ```

5. **Monitorar e Confirmar Conclusão:**
   ```powershell
   orca orchestration check --wait --types worker_done --timeout-ms 900000 --json
   orca orchestration check --ack <delivery_id> --json
   ```

---

## 📌 4. Passo 3: Validação & Code Review Obrigatório

Assim que o OpenCode concluir a etapa:

1. **Validação Estrita de Sintaxe Lua 5.0 (WoW 1.12.1):**
   - Executar `luac -p` em cada arquivo `.lua` criado ou modificado:
     ```powershell
     luac -p "caminho/do/arquivo.lua"
     ```
   - **Regras Críticas de Sintaxe:**
     - ❌ **PROIBIDO** operador de comprimento `#table` ou `#"string"` (usar `table.getn(t)` ou `string.len(s)`).
     - ❌ **PROIBIDO** vararg `...` de Lua 5.1 fora dos padrões aceitos pelo FrameXML 1.12.
     - ❌ **PROIBIDO** operadores `//`, `!=`, `goto`, `continue`.
     - ❌ **PROIBIDO** chamadas a APIs inexistentes no WoW 1.12 (como `GetQuestID` nativo da Blizzard).
2. **Inspeção de Diff:**
   - Verificar alterações com `git status` e `git diff --stat`.
3. **Parada Crítica e Validação do Usuário:**
   - Apresentar um resumo claro e conciso das mudanças ao usuário.
   - Solicitar a validação in-game via `/reload` antes de avançar para qualquer etapa posterior.

---

## ⚠️ 5. Regras Rígidas de Execução (Obrigatório Incluir no Prompt do Coder)

Sempre que uma instrução for despachada para o **OpenCode**, o prompt DEVE conter no cabeçalho o seguinte bloco explícito:

```text
REGRAS RÍGIDAS DE EXECUÇÃO:
- AMBIENTE: World of Warcraft Vanilla 1.12.1 (Turtle WoW) / Lua 5.0.
- PROIBIDO usar operador `#` (como `#t` ou `#str`). Use `table.getn(t)` e `string.len(str)`.
- PROIBIÇÃO ABSOLUTA DE GIT: PROIBIDO usar `git commit` ou `git push`. Qualquer operação de commit causará descarte do seu trabalho.
- ISOLAMENTO DE PASSO: O código deste passo DEVE ser 100% autônomo e executável, sem quebrar o addon no WoW 1.12.
- Toda modificação deve ser validada localmente com `luac -p <arquivo.lua>` antes de reportar conclusão.
- Mantenha a edição cirúrgica, sem reescrever arquivos desnecessariamente.
```

---

> [!CAUTION]
> # 🛑 REFORÇO FINAL MANDATÓRIO: NUNCA COMMITE, NUNCA FAÇA PUSH & SEMPRE FAÇA PARADA CRÍTICA
> **RELEMBRE ANTES DE QUALQUER RESPOSTA OU ENCERRAMENTO DE TURNO:**
> - Não faça `git commit`.
> - Não faça `git push`.
> - Não permita que o OpenCode faça `git commit` ou `git push`.
> - Aguarde sempre a ordem textual direta do usuário para commits/pushes. Se autorizado, o push é feito **uma única vez**.
> - **NUNCA** avance para o próximo passo sem a parada crítica e aprovação explícita do usuário após teste no jogo com `/reload`!
