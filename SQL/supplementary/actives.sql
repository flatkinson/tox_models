----------------------------------------------------------------------------------------------------
-- 
--  tt_curve_data_actives_subset.sql
-- 
-- Create convenience table with only targets of interest.
-- 
----------------------------------------------------------------------------------------------------

def min_n_active = 40

--

-- drop table tt_curve_data_actives_subset2;

--

create table tt_curve_data_actives_subset2 as
select
    a.symbol
  , a.usmiles
from
  tt_curve_data_actives a
  join (
    select
        symbol
      , species
      , count(*) as count
    from
      tt_curve_data_actives
    group by
        symbol
      , species
  ) b on a.symbol = b.symbol and a.species = b.species
where
    a.species = 'Human'
and b.count >= &min_n_active
order by
    a.symbol
  , a.usmiles
;

----------------------------------------------------------------------------------------------------
-- End
----------------------------------------------------------------------------------------------------