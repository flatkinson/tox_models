----------------------------------------------------------------------------------------------------
-- 
-- Count active and inactive records for compounds.
-- 
-- Note that 'compounds' are here defined in terms of USMILES.
-- 
-- Note also that 'targets' are defined in terms of symbol/species pairs.
--
-- Note use of source table 'tt_curve_data_v2'; this is to get a full picture of the inactives.
-- 
----------------------------------------------------------------------------------------------------

-- drop table tt_activity_counts;

--

-- 

create table tt_activity_counts as
select
    a.*
  , case when ((a.n_active > 0) and (a.n_inactive > a.n_active)) then 1 else 0 end as suspect
from (
  select
      a.symbol
    , a.species
    , b.usmiles
    , count(case when nvl(a.active, 0) = 1 then 1 end) n_active
    , count(case when nvl(a.active, 0) = 0 then 1 end) n_inactive
    , count(*) n_total
  from
    tt_curve_data_v2 a
    join tt_structure_lookup b on a.parent_cmpd_chemblid = b.cmpd
  where
    a.exclude = 0
  group by
      a.symbol
    , a.species
    , b.usmiles
  ) a
order by
    a.symbol
  , a.species
  , a.usmiles
;

----------------------------------------------------------------------------------------------------
-- End
----------------------------------------------------------------------------------------------------
