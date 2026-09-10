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
  - **Serialização Obrigatória:** Operações em lote no Inbox devem aguardar eventos (`MAIL_SUCCESS`, `MAIL_INBOX_UPDATE`) e nunca rodar em loop síncrono `for` para evitar perdas ou desync com o servidor.
- **Entrada de Texto / Teclado Virtual:** O addon pode injetar strings livremente em `EditBox` (`target:SetText()`, `target:Insert()`) ou passar os buffers diretamente para a chamada `SendMail()`.

---

## 3. Arquitetura de UI e UX para Console

### 3.1 Layout Split-View (Baseado no MerchantMenu)
- **Container Principal:** Janela 9-Slice (`Carved_9Slides.tga`) com Dimmer escurecido no fundo, dimensões responsivas (`94% x 85%`).
- **Coluna Esquerda (INBOX):** Lista paginada com 7 linhas por página, exibindo ícone do anexo/carta, remetente, assunto, dias restantes e badges (não lida, dinheiro, COD).
- **Coluna Direita (COMPOSIÇÃO / INVENTÁRIO):**
  - Sub-aba **INVENTÁRIO:** Lista de itens das bolsas para escolha de anexo (reaproveitando `ParseBagItem` e categorias).
  - Sub-aba **COMPOR:** Painel com campos selecionáveis:
    1. `Para:` (Destinatário + Autocomplete de Alts/Histórico)
    2. `Assunto:` (Auto-preenche com nome do anexo se vazio)
    3. `Mensagem:` (Abre Teclado Virtual para corpo do texto)
    4. `Dinheiro:` (Abre seletor numérico estilo alarme de celular)
    5. `Botão Enviar:` (Com custo de postagem e validação de saldo)
- **Painel de Detalhes Superior/Inferior:** Exibe conteúdo da carta selecionada ou tooltip rico do item anexado.
- **Footer de Atalhos (Controle):**
  - `[A]` Confirmar / Abrir / Enviar
  - `[X]` Teclado / Digitar / Anexar Item
  - `[Y]` Retirar Tudo / Excluir
  - `[B]` Voltar / Fechar
  - `[LB] / [RB]` Alternar Colunas
  - `[LT] / [RT]` Alternar Filtros / Sub-abas
  - `[D-Pad]` Navegar e Ajustar Valores

---

## 4. Componentes Especiais

### 4.1 Seletor de Dinheiro Estilo "Alarme de Celular" (Reels/Rolos)
- **Conceito Visual:** Três colunas verticais independentes: `[ Ouro ] [ Prata ] [ Cobre ]`.
- **Navegação:**
  - `D-Pad LEFT / RIGHT:` Seleciona a casa/coluna ativa.
  - `D-Pad UP / DOWN:` Gira o número para cima/baixo (com wrap circular `0-9` e carry opcional).
  - `Hold-to-Repeat:` Rolagem contínua suave (`0.35s` delay inicial, `0.12s` intervalo).
- **Validação:** Exibe saldo disponível, taxa de postagem calculada em tempo real (`GetSendMailPrice()`) e impede envio de valores superiores ao dinheiro do jogador.

### 4.2 Teclado Virtual Desacoplado para Console (`UI/VirtualKeyboard.lua`)
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

## 5. Fases de Implementação

### Fase 1: Infraestrutura Básica e Leitura do Inbox
- Criação de `UI/MailMenu.lua` e registro no `.toc` e `Core.lua`.
- Tratamento dos eventos: `MAIL_SHOW`, `MAIL_CLOSED`, `MAIL_INBOX_UPDATE`, `MAIL_SUCCESS`.
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
  - `UI/MailMenu.lua`
  - `UI/VirtualKeyboard.lua`
- **Modificados:**
  - `ConsoleModeVanilla.toc` (inclusão dos novos arquivos)
  - `Core.lua` (inicialização do módulo de Mail)
  - `Keybindings.lua` (redirecionamento de inputs do D-Pad/ações quando `MailMenu` estiver aberto)
  - `Hooks.lua` (interceptação de `MAIL_SHOW`, `MailFrame` e prioridade em `CloseTopFrame`)
  - `Cursor.lua` (registro de prioridade modal para o Teclado Virtual)
