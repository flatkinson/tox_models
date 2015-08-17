alter table tt_curve_data_v1 add exclude number(1);

--

update
  tt_curve_data_v1 a
set
  a.exclude = (
    select
      b.exclude
    from
      tt_chembl_targets b
    where
      a.symbol = b.symbol and a.target_chemblid = b.chembl_id
  )
;

----------------------------------------------------------------------------------------------------

alter table tt_curve_data_v2 add exclude number(1);

--

update
  tt_curve_data_v2 a
set
  a.exclude = (
    select
      b.exclude
    from
      tt_chembl_targets b
    where
      a.symbol = b.symbol and a.target_chemblid = b.chembl_id
  )
;

----------------------------------------------------------------------------------------------------

commit;

----------------------------------------------------------------------------------------------------
-- End
----------------------------------------------------------------------------------------------------

