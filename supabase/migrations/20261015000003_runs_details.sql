-- =============================================================================
-- Prospection IA — Migration 3 : `runs.details` (ticket S1-08, décision D-002)
-- Réf. cahier des charges §4 (observabilité), §7.1 (table runs), ADR 0005
-- =============================================================================
-- Pourquoi une NOUVELLE migration : la migration 1 est appliquée depuis S0-02, et une
-- migration appliquée ne se modifie jamais.
-- Pourquoi le numéro 3 et non 2 : le numéro 2 est réservé par la branche
-- `feat/s1-05-garde-fou-naf` (garde-fou de format NAF, PR #1 en review). Le réutiliser
-- créerait deux migrations de même préfixe, appliquées dans un ordre alphabétique qui ne
-- serait plus l'ordre chronologique. On ne touche pas au numéro d'un autre ticket.
--
-- DÉCISION D-002, rappelée ici parce que c'est le seul endroit que lira un agent SQL :
-- `runs.items_processed` prend un sens UNIQUE — le nombre de lignes ÉCRITES en base.
-- Les volumes récupérés et écartés ne peuvent donc plus y être confondus : ils vivent
-- dans `runs.details`. C'est ce qui rend le taux de rejet calculable, donc le calibrage
-- d'une campagne possible (ADR 0005 le demandait déjà : « nouvelles décisions » à acter).
-- -----------------------------------------------------------------------------

alter table public.runs add column if not exists details jsonb;

comment on column public.runs.details is
  'Compteurs de ciblage du run, par clé. Clés attendues : recuperees (entier — entreprises retournées par l''API) et ecartees (entier — écartées par la règle de siège d''ADR 0005 ou le filtre d''effectif de D-008). Écrit par WF1 (ticket S1-02). Ne jamais y remettre un compteur qui a déjà un sens ailleurs : items_processed = lignes ÉCRITES (D-002). Exemple : {"recuperees": 30, "ecartees": 18} — soit un taux de rejet de 37,5 %.';

comment on column public.runs.items_processed is
  'Nombre de lignes ÉCRITES en base par ce run — sens unique (décision D-002). Les volumes récupérés et écartés sont dans details : sans cette séparation, le taux de rejet est incalculable et aucune campagne ne peut être calibrée.';

-- Rien à ajouter côté sécurité : `runs` a déjà sa RLS, ses policies et ses privilèges
-- (migration 1). Une colonne hérite des droits de sa table.
-- Aucun index : les compteurs se lisent toujours par run (`where id = …`), jamais par
-- valeur de `details` — un index serait un coût d'écriture sans usage.

-- Le dashboard (PostgREST) doit voir la nouvelle colonne sans redémarrage.
notify pgrst, 'reload schema';
