-- drop table tt_curve_data_v2;

--

-- Note that the join to the 'compound_structures' table guarantees that a structure is available and that inorganics and peptides are excluded.

create table tt_curve_data_v2 as
select
    x.symbol
  , x.approved_name
  , x.species
  , x.chembl_id as target_chemblid
  , a.pref_name
  , a.target_type
  , b.chembl_id as assay_chemblid
  , b.description
  , j.chembl_id as parent_cmpd_chemblid
  , g.canonical_smiles as smiles
  , h.mw_freebase as amw
  , h.heavy_atoms as nat
  , i.chembl_id as cmpd_chemblid
  , c.activity_id
  , c.standard_type
  , c.standard_relation
  , c.standard_value
  , c.standard_units
  , c.pchembl_value
  , c.activity_comment
  , c.data_validity_comment
  , c.potential_duplicate
  , d.compound_key
  , c.published_type
  , c.published_relation
  , c.published_value
  , c.published_units
  , e.chembl_id as doc_chemblid
  , e.pubmed_id
  , case when e.journal is not null then e.journal || ', v. ' || e.volume || ', p. ' || e.first_page || ' (' || e.year || ')' else '' end as citation
  , case when pchembl_value >= 5.0 then 1 else 0 end as active
from
  tt_chembl_targets x
  join chembl_20_app.target_dictionary a   on x.chembl_id       = a.chembl_id
  join chembl_20_app.assays b              on a.tid             = b.tid
  join chembl_20_app.activities c          on b.assay_id        = c.assay_id
  join chembl_20_app.compound_records d    on c.record_id       = d.record_id
  join chembl_20_app.docs e                on c.doc_id          = e.doc_id
  join chembl_20_app.molecule_hierarchy f  on c.molregno        = f.molregno
  join chembl_20_app.compound_structures g on f.parent_molregno = g.molregno
  join chembl_20_app.compound_properties h on f.parent_molregno = h.molregno
  join chembl_20_app.chembl_id_lookup i    on f.molregno        = i.entity_id -- compound
  join chembl_20_app.chembl_id_lookup j    on f.parent_molregno = j.entity_id -- parent
where
    i.entity_type = 'COMPOUND'
and j.entity_type = 'COMPOUND'
and h.mw_freebase <= 1000.0 -- Above this AMW, ChEMBL does not compute molecular properties etc.
and g.canonical_smiles not like '%.%' -- Mixtures
and c.standard_type in ('IC50', 'EC50', 'ED50', 'AC50', 'XC50', 'Ki', 'Kd', 'Potency') -- Dose-response assays
and (
      (c.standard_units = 'nM' and c.standard_value is not null) -- N.B. Any relation accepted
   or regexp_like(c.activity_comment, '(^|\W)' || '(not active|inactive|no activity|no inhibition|no effect)' || '(\W|$)', 'i') -- Inactives without numerical value
)
order by
    x.symbol
  , x.species
  , a.pref_name
  , j.chembl_id
;

--

create index tt_curve_data_v2_target_idx1 on tt_curve_data_v2(target_chemblid);

create index tt_curve_data_v2_target_idx2 on tt_curve_data_v2(symbol, species);

create index tt_curve_data_v2_target_idx3 on tt_curve_data_v2(symbol);

----------------------------------------------------------------------------------------------------

-- Alternative pActivity definition (slightly more generous than pchembl_value)...

alter table tt_curve_data_v2
add
(
    pmodifier varchar2(2)
  , pactivity number(4, 2)
)
;

--

update tt_curve_data_v2
set
    pmodifier = case standard_relation when '>' then '<' when '>>' then '<<' when '>=' then '<=' when '<' then '>' when '<=' then '>=' else standard_relation end
  , pactivity = -log(10, standard_value * power(10, -9))
where
    standard_value is not null
and standard_value > 0
;

----------

-- Active flag based on alternative pActivity definition...

alter table tt_curve_data_v2
add
(
  pactive number(1)
)
;

--

update tt_curve_data_v2
set
  pactive = case
    when
        pactivity >= 5
      and (pmodifier not in ('<', '<=', '<<') or pmodifier is null)
      and (activity_comment is null or not regexp_like(activity_comment, '(^|\W)' || '(not active|inactive|no activity|no inhibition|no effect)' || '(\W|$)', 'i'))
    then 1
    else 0
    end
;

----------------------------------------------------------------------------------------------------
-- End
----------------------------------------------------------------------------------------------------
