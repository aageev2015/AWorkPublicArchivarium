-- in case if production backup was made before areas


--- on base
use AwesomeSystemV0_PROD_2020_02_15_base
select dateadd(hh, -1, max(STAMP)) from history


-- on area 1
use AwesomeSystemV0_PROD_2020_02_15_Area1
declare @base_last_date datetime =  '2021-03-12 10:11:15.325' -- value from base result

update sending_order
set modification_date=dateadd(ss,1,modification_date)
where modification_date >= @base_last_date and modification_date=base_modification_date

update getting_order
set modification_date=dateadd(ss,1,modification_date)
where modification_date >= @base_last_date and modification_date=base_modification_date


-- on area 2
use AwesomeSystemV0_PROD_2020_02_15_Area2
declare @base_last_date datetime =  '2021-03-12 10:11:15.325' -- value from base result

update sending_order
set modification_date=dateadd(ss,1,modification_date)
where modification_date >= @base_last_date and modification_date=base_modification_date

update getting_order
set modification_date=dateadd(ss,1,modification_date)
where modification_date >= @base_last_date and modification_date=base_modification_date