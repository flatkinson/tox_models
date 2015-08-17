----------------------------------------------------------------------------------------------------
-- 
-- tt_curve_data_actives.sql
-- 
-- Create summary table of distinct active compounds for each target.
-- 
-- * Compounds are defined by USMILES.
-- 
-- * Targets are defined as symbol/species pairs.
-- 
-- * Size filtering (based on minimum and maximum heavy atom counts) is applied at this stage.
-- 
-- * Note the use of source table 'tt_curve_data_v1', as only actives are of interest here.
-- 
----------------------------------------------------------------------------------------------------

-- drop table tt_curve_data_actives;

--

create table tt_curve_data_actives as
select
    symbol
  , species
  , usmiles
  , wm_concat(distinct cmpd) as cmpds -- NB distinct clause here orders concatenated values
  , count(cmpd) as count
from (
  select distinct
      a.symbol
    , a.species
    , a.parent_cmpd_chemblid as cmpd
    , b.usmiles
  from
    tt_curve_data_v1 a
    join tt_structure_lookup b on a.parent_cmpd_chemblid = b.cmpd
  where
      a.exclude = 0
  and a.active = 1
  and b.nat >= 10
  and a.nat <= 50
  ) a
group by
    symbol
  , species
  , usmiles
order by
    symbol
  , species
  , usmiles
;

----------------------------------------------------------------------------------------------------

-- Sanity check: this should give same number of rows (194,402)
 
select distinct
    a.symbol
  , a.species
  , a.usmiles
from
  tt_activity_counts a
  join tt_structure_lookup b on a.usmiles = b.usmiles
where
   a.n_active > 0
   and b.nat >= 10
and b.nat <= 50
;

----------------------------------------------------------------------------------------------------
-- End
----------------------------------------------------------------------------------------------------