-- Camada de compatibilidade OctoWoW (overlay nao-destrutivo do Capy).
-- Formato identico ao Capy: ConsoleMode_SpellDescDB_Octo[id] = { n, r, d, t, pt }
-- + ConsoleMode_SpellDescDB_Octo_ByKey["nome|grau"] = id (+ alias "nome|").
-- VEREDITO DBC 23/09/2026 (extracao MPQ por MPQ do cliente octowow):
-- patch-9 Octo == patch-9 Capy (nrec 27916 nos dois; Spell.dbc 27938523 bytes);
-- os customs do patch-5 (57847 Way of the Samurai, 62300-62302 mascotes,
-- 62310 Cone of Shame, 30997, 6559...) NAO sobrevivem ao override whole-file
-- do patch-9 e sao invisiveis no cliente live. Logo: overlay DBC = vazio.
-- Conteudo futuro: customs server-side descobertos via ConsoleModeDB.spellMissing
-- jogando no Octo com a camada ATIVA (toggle em ADDON_CFG ou /cm octo).
-- Consultada por CM:GamePT_SpellDesc SOMENTE quando CM:IsOctoActive().
ConsoleMode_SpellDescDB_Octo = {}
ConsoleMode_SpellDescDB_Octo_ByKey = {}
