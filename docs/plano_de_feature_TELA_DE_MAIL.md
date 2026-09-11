# Plano de Feature: Tela de Correio (MAIL) e Teclado Virtual para Console

## 1. Visão Geral e Objetivo
Criar uma interface moderna, nativa para controle/gamepad, que substitua o `MailFrame` padrão do WoW 1.12 (Turtle WoW), seguindo a mesma arquitetura split-view e padrões visuais da tela de comércio (`MerchantMenu.lua`). A feature inclui leitura e retirada de cartas da Caixa de Entrada (Inbox), composição de novas cartas, seleção de anexos do inventário, envio de dinheiro através de um seletor numérico no estilo "alarme de celular", e um Teclado Virtual próprio com suporte a autocomplete de alts e histórico de destinatários.

---

## 2. Validação Técnica (WoW 1.12 / Lua 5.0)

### 2.1 Viabilidade e Mecanismos da API 1.12
- **Envio 100% Programático:** A função `SendMail(destinatario, assunto, corpo)` é chamada sem restrições de proteção (sem taint/secure frames no 1.12), desde que a mailbox esteja aberta (evento `MAIL_SHOW` ativo).
- **Limite de Anexos do Vanilla:** O cliente 1.12 suporta exatamente **1 anexo por carta** (`ATTACHMENTS_MAX_SEND = 1`). Envio de múltiplos itens exige fila de cartas seriadas ("Parte X de Y").
- **Fluxo de Anexo e Dinheiro:**
  - Item: `PickupContainerItem(bag, slot)` seguido de `ClickSendMailItemButton()`.
  - Dinheiro: `SetSendMailMoney(copper)` (dinheiro normal).
  - Custo de Postagem: `GetSendMailPrice()`.
- **Inbox e Retiradas:**
  - Atualização: `CheckInbox()` dispara `MAIL_INBOX_UPDATE`.
  - Dados: `GetInboxNumItems()` e `GetInboxHeaderInfo(index)` retornam remetente, assunto, dinheiro, COD, dias restantes, anexo e flags.
  - Ações: `TakeInboxMoney(index)`, `TakeInboxItem(index)`, `DeleteInboxItem(index)`, `ReturnInboxItem(index)`.
  - **Serialização Obrigatória:** Operações em lote no Inbox devem aguardar eventos (`MAIL_SEND_SUCCESS`, `MAIL_INBOX_UPDATE`) e nunca rodar em loop síncrono `for` para evitar perdas ou desync com o servidor.
- **Entrada de Texto / Teclado Virtual:** O addon pode injetar strings livremente em `EditBox` (`target:SetText()`, `target:Insert()`) ou passar os buffers diretamente para a chamada `SendMail()`.

---

## 3. Arquitetura de UI e UX para Console

### 3.1 Arquitetura de Telas (duas telas, troca por LB/RB)
- **Duas telas em janela única:** INBOX (default ao abrir) ↔ COMPOR. Troca: **RB vai p/ nova mensagem, LB volta p/ caixa**, nas duas telas.
- **Indicador de aba centralizado** abaixo do título `|cffe09a15CORREIO|r`: mostra o destino + o botão (`NOVA MENSAGEM [ícone RB]` na inbox; `[ícone LB] CAIXA DE MENSAGENS` no compor).
- **Tela INBOX:**
  - Esquerda = lista como está (7 linhas, filtros, paginação).
  - Direita = detalhe FULL da carta selecionada (remetente, assunto, expiração, dinheiro/COD, anexo, corpo do texto) + **3 botões-textura em UMA linha**: `RETIRAR`, `DEVOLVER`, `APAGAR` (estilo do botão Sair do header: backdrop + ícone, sem texto puro representando botão).
- **Tela COMPOR:**
  - Esquerda = NOVA CARTA com 5 áreas + envio: `Para`, `Assunto`, `Mensagem`, `Dinheiro`, `Itens` (slots automáticos, navegáveis) e botão **ENVIAR centralizado embaixo** com custo de postagem (`ENVIAR (postagem 30c)`).
  - Direita = INVENTÁRIO em grade estilo MainMenu (navegação por células com borda, igual ao VK; A adiciona o item à carta, Y abre janela de quantidade, X sobre item anexado o devolve à bolsa).
  - Item anexado = slot com **fundo/borda vermelhos** no inventário (+ badge "NA CARTA"); **X remove da carta de onde quer que o foco esteja**, sem precisar navegar até a área de itens.
- **Modais (FULLSCREEN_DIALOG/50):** Quantidade (Y no inventário do compor), Dinheiro (reels, §4.1), confirmação de APAGAR com anexo/valores, VK (§4.2).
- **Mapas de footer por tela:**
  - Inbox: `D-Pad Navegar • A Entrar no detalhe • Y Retirar tudo • LT/RT Filtros • RB Nova mensagem • B Voltar/Fechar`
  - Compor: `D-Pad Navegar • A Adicionar/Confirmar • X Tirar item • Y Quantidade • LT/RT Pular metade • LB Caixa • B Voltar/Fechar`

### 3.2 Regras de Navegação e Input (valem nas duas telas)
- **D-Pad espacial:** move o foco na direção apertada; se houver área navegável vizinha, o foco **atravessa** (lista ↔ botões do detalhe; campos ↔ inventário); borda sem vizinho = **fica parado**. Sem wrap, sem tecla especial de travessia.
- **A na linha do inbox** = foco entra no detalhe (vai p/ RETIRAR); D-Pad ←/→ percorre os 3 botões; **B com foco no detalhe = volta p/ lista** (não fecha a janela).
- **B fecha só o topo da pilha:** VK/modal/detalhe primeiro; a janela do MAIL por último. ESC = B. (`CloseTopFrame` com o VK no topo da ordem.)
- **Y contextual:** inbox sem modal/VK aberto = retirar tudo de todas as cartas (fila serializada, imprescindível); compor = janela de quantidade; com VK/modal aberto = Y pertence a eles (no VK, Y = shift).
- **LT/RT:** inbox = ciclar filtros; compor = salto p/ o **primeiro elemento da próxima (RT) / anterior (LT) metade** (topo dos campos / slot 1 do inventário).
- **Mouse + teclado físico:** clique direto em tudo; todo campo tem EditBox focável (Para/Assunto/Mensagem/Dinheiro, inclusive valor do dinheiro) — o modal/VK é só o caminho do gamepad.

---

## 4. Componentes Especiais

### 4.1 Seletor de Dinheiro Estilo "Alarme de Celular" (Reels por Dígito)
- **Conceito Visual:** cada moeda vira reels de 0–9 com wrap (9+1 volta a 0): **Ouro = 4 dígitos (até 9999g), Prata = 2, Cobre = 2**. Igual ao alarme do celular: gira-se cada caractere até construir o valor.
- **Navegação:**
  - `D-Pad LEFT / RIGHT:` Seleciona o dígito ativo.
  - `D-Pad UP / DOWN:` Gira o dígito (com wrap circular `0-9`).
  - `Hold-to-Repeat:` Segurar gira contínuo (`0.35s` delay inicial, `0.12s` intervalo — mesmos números do VK).
  - `A` Confirma, `B` cancela (fecha só o modal, §3.2).
- **Digitação física:** o campo Dinheiro tem EditBox focável (mouse clica e digita o valor) — o modal de reels é só o caminho do gamepad.
- **Validação:** Exibe saldo disponível, taxa de postagem calculada em tempo real (`GetSendMailPrice()`) e impede valores superiores ao dinheiro do jogador.

### 4.2 Teclado Virtual Desacoplado para Console (`UI/VirtualKeyboard.lua`)
> NOTA: componente pronto e validado até VK-4 (main `b62a58e`; plano `docs/plano_de_feature_VIRTUAL_KEYBOARD.md`). A MailScreen consome o contrato congelado abaixo; se o teclado estiver ausente, o campo foca seu EditBox para digitação no teclado físico.
> Contrato congelado do VK (não mexer sem motivo): `ConsoleMode.VirtualKeyboard:Open({title, initialText, maxLetters, multiLine, autoCompleteList, onConfirm*, onCancel, targetEditBox})`, `Close()` (fecha e dispara `onCancel`/descarta), `IsOpen()`. `onConfirm` é obrigatório. Mapa vigente: A insere, B fecha, X apaga (hold), Y shift, D-Pad navega (hold), L1/R1 páginas, Start OK. Autocomplete: fileira de até 4, prefixo case-insensitive, UP sobe / A preenche / DOWN volta. O VK **nunca lê/escreve SavedVariables** — histórico e política (move-para-frente, sem duplicata, teto 20) são do MailScreen, em SV separada `ConsoleModeMailHistory` (+1 nome na linha `SavedVariables` do `.toc`; `ConsoleModeDB` segue só com alts).
- **Arquitetura Modular / Standalone:** O Teclado Virtual é projetado como um módulo de serviço independente (`ConsoleMode.VirtualKeyboard`), podendo ser invocado por qualquer tela ou componente do addon (Mail, Chat, Busca de Bags, Macros, Configurações, etc.).
- **API Pública do Teclado:**
  - `VirtualKeyboard:Open(config)`:
    - `config.title`: Título do modal (ex: `"Destinatário"`, `"Mensagem"`, `"Buscar Item"`).
    - `config.initialText`: Texto pré-carregado no buffer.
    - `config.maxLetters`: Limite de caracteres (default livre ou `255`/`2000`).
    - `config.multiLine`: `true/false` (ativa quebra de linha com `Y` ou tecla dedicada).
    - `config.autoCompleteList`: Array opcional de sugestões (ex: Alts, Histórico, Nomes de Guilda).
    - `config.onConfirm(text)`: Callback disparado ao salvar/concluir.
    - `config.onCancel()`: Callback disparado ao cancelar/fechar sem salvar.
    - `config.targetEditBox`: (Opcional) EditBox do WoW associado para sincronização direta.
  - `VirtualKeyboard:Close()`
  - `VirtualKeyboard:IsOpen() -> bool`
- **Frame Modal Prioritário:** Abre em camada `FULLSCREEN_DIALOG` com captura total de input de navegação do gamepad, sobrepondo qualquer menu ativo sem perder o estado da tela chamadora.
- **Grade de Teclas:** Layout paginado:
  - Aba 1: Minúsculas (`a-z`)
  - Aba 2: Maiúsculas (`A-Z`)
  - Aba 3: Números e Símbolos (`0-9`, pontuação)
  - Aba 4: Caracteres especiais/acentos ptBR (`ã, õ, ç, é, ...`)
- **Controles do Teclado:**
  - `D-Pad:` Navega pela matriz de botões.
  - `[A]:` Insere caractere selecionado.
  - `[B]:` Backspace (apaga caractere; segurar apaga contínuo com hold-to-repeat).
  - `[X]:` Shift / Alterna maiúsculas/minúsculas.
  - `[Y]:` Espaço (ou nova linha se `multiLine`).
  - `[L1] / [R1]:` Troca de páginas/layouts de teclado.
  - `[Start] / Botão Concluir:` Dispara `onConfirm(text)` e fecha o modal.
- **Autocomplete Genérico (Alts, Histórico, etc.):**
  - Quando `config.autoCompleteList` for fornecido, exibe uma barra de sugestões filtrável no topo da grade.
  - Navegação vertical (`D-Pad UP` a partir da primeira linha de teclas) salta o foco para a lista de sugestões, onde `[A]` seleciona e preenche o texto imediatamente.

---

## 5. Fases de Implementação (plano original — SUPERSEDEDO pelo §7)
> NOTA: as Fases 1–5 abaixo foram o plano original; o plano vigente é o §7 (M1–M5, espelho do mercador + nova arquitetura de telas do §3).

### Fase 1: Infraestrutura Básica e Leitura do Inbox
- Criação de `UI/MailScreen.lua` (componente desacoplado; era `UI/MailMenu.lua`, renomeado) e registro no `.toc` e `Core.lua`.
- Tratamento dos eventos: `MAIL_SHOW`, `MAIL_CLOSED`, `MAIL_INBOX_UPDATE`, `MAIL_SEND_SUCCESS` (corrigido: o plano citava `MAIL_SUCCESS`, nome errado no 1.12).
- Supressão do `MailFrame` nativo (`alpha 0`, off-screen).
- Leitura de cabeçalhos (`GetInboxHeaderInfo`), paginação de 7 linhas, filtros (Todos, Não-lidos, Com Anexo).
- Ações no Inbox: Retirar Dinheiro, Retirar Item, Excluir, Devolver e "Retirar Tudo" (em fila serializada).

### Fase 2: Composição de Cartas e Teclado Virtual Base
- Criação de `UI/VirtualKeyboard.lua` com grade alfanumérica e suporte ao D-Pad.
- Implementação da aba de Composição com campos: `Para`, `Assunto`, `Mensagem`.
- Integração do Autocomplete de Alts e Histórico de envios recentes (persistido em `ConsoleModeDB`).
- Lógica de auto-preenchimento do assunto ao anexar um item.
- Validação de envio e disparo de `SendMail()`.

### Fase 3: Seletor de Dinheiro Estilo Alarme e Anexos de Bolsa
- Implementação do modal numérico com rolos giratórios para Ouro, Prata e Cobre.
- Sub-aba de inventário para seleção e inserção de 1 anexo do inventário via `PickupContainerItem` + `ClickSendMailItemButton`.
- Tratamento de `MAIL_SEND_INFO_UPDATE` e validação do custo de postagem.

### Fase 4: Fila Multi-Item e Suporte a COD (v2)
- Fila automatizada para envio de múltiplos itens em cartas separadas sequenciais ("Parte X de Y").
- Suporte a anexo com Cobrança na Entrega (C.O.D.) com teto de 10.000g.

### Fase 5: Polimento, Áudio e Compatibilidade de Chat
- Correção dos hooks de `chatActive` (`ChatFrameEditBox` e `SendMail*EditBox`) para garantir que o D-Pad não conflite com digitação em teclado físico.
- Priorização de fechamento (`Hooks:CloseTopFrame`).
- Sons de interface, feedback visual de envio com sucesso e mensagens de erro descritivas.

---

## 6. Arquivos Impactados
- **Novos:**
  - `UI/MailScreen.lua` (componente desacoplado da tela de correio; `ConsoleMode_MailScreen` / `CM.mailScreen`)
  - `UI/VirtualKeyboard.lua` — componente pronto, consumido via contrato congelado (plano `docs/plano_de_feature_VIRTUAL_KEYBOARD.md`); a MailScreen consome, não implementa.
- **Modificados:**
  - `ConsoleModeVanilla.toc` (inclusão dos novos arquivos + `ConsoleModeMailHistory` na linha `SavedVariables`)
  - `Core.lua` (inicialização do módulo de Mail)
  - `Keybindings.lua` (redirecionamento de inputs do D-Pad/ações quando `MailScreen` estiver aberto)
  - `Hooks.lua` (interceptação de `MAIL_SHOW`, `MailFrame` e prioridade em `CloseTopFrame`)
  - `Cursor.lua` (registro de prioridade modal para o Teclado Virtual)

---

## 7. Plano de Execução Aprovado (Fases M1–M5, espelho do mercador)

Construção do mercador (referência): Fase 1 detecção+supressão → Fase 2 janela visual → Fase 3 dados+DetailCard → Fases 5/6 ações+modais → fixes. Concluído no mail (Fase 1): esqueleto+registro (`75ba84c`), eventos (`4b5539a`), supressão segura (`8f7ff24`), leitura inbox+filtros sem visual (`5387081`).

### Fase M1: Esqueleto da janela aparece
- `CreateUI` no molde `MerchantMenu:1302`: dimmer (`0,0,0,0.65`), 9-slice `Carved_9Slides.tga`, janela responsiva 94%x85% (clamp 840–1440/520–920), header `|cffe09a15CORREIO|r` + botão Sair, `contentArea` + 2 colunas + footer, `UISpecialFrames`/ESC, `HIGH/10`.
- Fiação mínima: `Open`/`Close` reais, `Enter/ExitNavigationMode`, B fecha, D-Pad move seleção (placeholder).
- Validação: mailbox → janela aparece; B/ESC fecha; sem erro Lua.

### Fase M2: Os mails aparecem
- Linhas do inbox 7×42px (ícone 32, cursor dourado, highlight, remetente+assunto+dias+selos), painel de detalhes, filtros no LT/RT, paginação `Item X de Y (Pág. P/T)`, colunas LB/RB.
- Validação: navegar só no gamepad, trocar filtro, paginar.

### Fase M3: Lógica dos botões do inbox
- Detalhe FULL à direita (M2) + linha única de botões-textura `RETIRAR | DEVOLVER | APAGAR`.
- A sobre a linha entra no detalhe (foco em RETIRAR); B volta o foco p/ lista; `CloseTopFrame` + pilha de B (§3.2) + guards `Keybindings`/`Cursor`.
- RETIRAR pega tudo da carta (dinheiro + item), com log por carta; **Y na inbox = retirar tudo de todas as cartas em fila serializada por `MAIL_INBOX_UPDATE`**; DEVOLVER devolve ao remetente; APAGAR exclui (com modal de confirmação se houver anexo/valores não retirados).
- Validação: char com cartas (dinheiro+item+lixo); logs por carta; sem perda.

### Fase M4: Tela de enviar mensagem (inclui VK-5: MailScreen consome o VirtualKeyboard)
- Tela COMPOR (§3.1): esquerda NOVA CARTA (`Para`/`Assunto`/`Mensagem`/`Dinheiro`/`Itens` + ENVIAR centralizado embaixo com postagem); direita INVENTÁRIO em grade estilo MainMenu; navegação espacial + LT/RT salto de metade (§3.2).
- Inventário: A adiciona o item à carta; **Y abre modal de quantidade** (D-Pad ↑↓ ajusta, teto = tamanho da pilha, A confirma, B cancela, mouse digita); **X sobre item anexado o devolve à bolsa** de onde estiver o foco; slot anexado com fundo/borda vermelhos + badge.
- **Fila multi-item (1.12 = 1 anexo por carta):** o usuário põe quantos itens quiser; o sistema envia cada item numa carta nova, copiando assunto+texto; o **dinheiro vai só na 1ª carta**; validação soma N× postagem antes de começar; log `Enviando X de N...`; fila serializada por eventos.
- Assunto auto-preenche com o nome do 1º item adicionado (se vazio).
- Chamadas VK (contrato congelado §4.2): `Para` → `Open({title="Destinatário", maxLetters=64, autoCompleteList=alts+histórico})`, `onConfirm` salva `composeTo` + atualiza histórico; `Assunto` → `Open({title="Assunto", initialText=nomeAnexo ou "", maxLetters=64})`; `Mensagem` → `Open({title="Mensagem", maxLetters=2000, multiLine=true})` (preserva `\n` e ç/ã).
- Dinheiro via modal de reels (§4.1); EditBox focável como fallback físico.
- Pós-envio: limpa todos os campos, permanece na tela de nova carta, log `Carta enviada.`.
- COD: **TODO futuro** (sem UI/código agora).
- Auditoria VK-5: Para com prefixo → sugere alt → confirma → campo mostra nome; multilinha com acentos preservada; confirmar Para 2x → reabrir mostra o último no topo; `/reload` preserva; abrir VK 3x seguidas alternando confirmar/cancelar sem erro Lua.

### Fase M5: Polimento
- Sons, `CloseTopFrame`, hooks `chatActive`, revisões Lua 5.0 + anti-bloqueio finais.

### Regras vigentes em todas as fases
- Identidade visual idêntica a MainMenu/MerchantMenu (fundo, cores, botões, tamanhos de texturas) — UX gamepad em primeiro lugar.
- Referência técnica de API: [shirsig/Mail](https://github.com/shirsig/Mail) (creditado no README).
- Parar para validação do usuário em cada fase; sem commit/push sem aprovação explícita.
- Validar qualidade + sintaxe (Lua 5.0 / WoW 1.12) como duas etapas distintas; zero API servidora fora de contexto (anti-bloqueio Blizzard).
