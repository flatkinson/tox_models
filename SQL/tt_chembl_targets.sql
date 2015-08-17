-- drop table tt_chembl_targets;

--

create table tt_chembl_targets
as
select
    x.symbol
  , x.approved_name
  , x.targets
  , row_number() over (partition by x.symbol, d.tax_id order by d.target_type, d.pref_name, d.chembl_id) as n_target
  , d.chembl_id
  , d.target_type
  , d.pref_name
  , case d.tax_id when 9606 then 'Human' when 10116 then 'Rat' end as species
from
  tt_symbols x
  join chembl_20_app.component_synonyms  a on x.symbol = upper(a.component_synonym)
  join chembl_20_app.component_sequences b on a.component_id = b.component_id
  join chembl_20_app.target_components   c on b.component_id = c.component_id
  join chembl_20_app.target_dictionary   d on c.tid          = d.tid
where
    a.syn_type = 'GENE_SYMBOL'
and d.target_type in ('SINGLE PROTEIN', 'PROTEIN COMPLEX')
and d.tax_id in (9606, 10116)
order by
    x.symbol
  , d.tax_id
  , n_target
;

----------------------------------------------------------------------------------------------------
-- End
----------------------------------------------------------------------------------------------------
