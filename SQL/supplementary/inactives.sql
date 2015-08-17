select
    symbol
  , count(parent_cmpd_chemblid) as n
from
  tt_curve_data_v2
where
  species = 'Human'
and active = 0
and (lower(description) not like '%pubchem%' and lower(description) not like '%drugmatrix%' )
group by
  symbol
order by
  n desc
;