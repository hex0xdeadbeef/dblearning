-- B-TREE INDEX is the default index in PostgreSQL
select * from aircrafts_data;
-- "SU9"	"{""en"": ""Sukhoi Superjet-100"", ""ru"": ""Сухой Суперджет-100""}"	3000
-- "320"	"{""en"": ""Airbus A320-200"", ""ru"": ""Аэробус A320-200""}"	5700
-- "321"	"{""en"": ""Airbus A321-200"", ""ru"": ""Аэробус A321-200""}"	5600
-- "319"	"{""en"": ""Airbus A319-100"", ""ru"": ""Аэробус A319-100""}"	6700
-- "733"	"{""en"": ""Boeing 737-300"", ""ru"": ""Боинг 737-300""}"	4200
-- "CN1"	"{""en"": ""Cessna 208 Caravan"", ""ru"": ""Сессна 208 Караван""}"	1200
-- "CR2"	"{""en"": ""Bombardier CRJ-200"", ""ru"": ""Бомбардье CRJ-200""}"	2700

drop index if exists aircrafts_data_range_idx;
create index aircrafts_data_range_idx on aircrafts_data using btree(range);
-- CREATE INDEX

set enable_seqscan = off;

explain (costs off)
select 
	*
from 
	aircrafts_data
where range = 3000;
-- "Index Scan using aircrafts_data_range_idx on aircrafts_data"
-- "  Index Cond: (range = 3000)"

explain (costs off)
select 
	*
from 
	aircrafts_data
where 
	range <= 3000;
-- "Index Scan using aircrafts_data_range_idx on aircrafts_data"
-- "  Index Cond: (range <= 3000)"

explain (costs off)
select 
	* 
from 
	aircrafts_data
where 
	range between 5000 and 7000;
-- "Index Scan using aircrafts_data_range_idx on aircrafts_data"
-- "  Index Cond: ((range >= 5000) AND (range <= 7000))"

-- THE SORTING ORDER
drop index if exists aircrafts_data_range_idx;
create index aircrafts_data_range_idx on aircrafts_data using btree(range desc);

drop view if exists aircrafts_v;
create view aircrafts_v as (
	select
		model,
		case 
			when range < 4000 then 1
			when range < 10000 then 2
			else 3
			end as class
	from 
		aircrafts_data
);

explain (costs off)
select * from aircrafts_v;
-- "Seq Scan on aircrafts_data ml"

drop index if exists range_condition_model_idx;
create index range_condition_model_idx on aircrafts_data using btree((case when range < 4000 then 1 when range < 10000 then 2 else 3 end), model);

explain (costs off)
select 
	*
from 
	aircrafts_v
order by class asc, model asc;
-- "Index Scan using range_condition_model_idx on aircrafts_data"

explain (costs off)
select 
	*
from 
	aircrafts_v
order by class desc, model desc;
-- "Index Scan Backward using range_condition_model_idx on aircrafts_data"


explain (costs off)
select 
	*
from 
	aircrafts_v
order by class asc, model desc;
-- "Incremental Sort"
-- "  Sort Key: (CASE WHEN (aircrafts_data.range < 4000) THEN 1 WHEN (aircrafts_data.range < 10000) THEN 2 ELSE 3 END), aircrafts_data.model DESC"
-- "  Presorted Key: (CASE WHEN (aircrafts_data.range < 4000) THEN 1 WHEN (aircrafts_data.range < 10000) THEN 2 ELSE 3 END)"
-- "  ->  Index Scan using range_condition_model_idx on aircrafts_data"

drop index if exists range_condition_model_idx_with_different_sort_order;
create index range_condition_model_idx_with_different_sort_order on aircrafts_data using btree(model asc, (case when range < 4000 then 1 when range < 10000 then 2 else 3 end) desc);

explain (costs off)
select 
	*
from 
	aircrafts_v
order by model asc, class desc;
-- Index Scan using range_condition_model_idx_with_different_sort_order on aircrafts_data

drop index if exists range_condition_model_idx_with_different_sort_order;
create index range_condition_model_idx_with_different_sort_order on aircrafts_data using btree(
    model,
    (case when range < 4000 then 1 when range < 10000 then 2 else 3 end) desc
);

-- NULL VALUES
-- B-Tree index indexes the null vals and supports the search by conditions "is null", "is not null"
drop index if exists flights_actual_arrival_idx;
create index if not exists flights_actual_arrival_idx on flights using btree(actual_arrival);

explain (costs off)
select 
	*
from
	flights
where
	actual_arrival is null;
-- "Bitmap Heap Scan on flights"
-- "  Recheck Cond: (actual_arrival IS NULL)"
-- "  ->  Bitmap Index Scan on flights_actual_arrival_idx"
-- "        Index Cond: (actual_arrival IS NULL)"

explain (costs off)
select
	*
from
	flights
order by	
	actual_arrival nulls last;
-- "Index Scan using flights_actual_arrival_idx on flights"

explain (costs off)
select
	*
from
	flights
order by	
	actual_arrival nulls first;
-- "Sort"
-- "  Sort Key: actual_arrival NULLS FIRST"
-- "  ->  Seq Scan on flights"


drop index if exists flights_actual_arrival_idx_nulls_first;
create index if not exists flights_actual_arrival_idx_nulls_first on flights using btree(actual_arrival nulls first);

explain (costs off)
select
	*
from
	flights
order by	
	actual_arrival nulls first;
-- "Index Scan using flights_actual_arrival_idx_nulls_first on flights"

select 42 > null;
-- null


-- THE METHOD'S PROPERTIES
select 
	a.amname as access_method_name, 
	p.name as property_name, 
	pg_indexam_has_property(a.oid, p.name) as is_property_presented 
from pg_am a,
	unnest(array['can_order', 'can_unique', 'can_multi_col', 'can_exclude']) as p(name)
where 
	a.amname = 'btree'
order by a.amname;
-- "btree"	"can_order"		true
-- "btree"	"can_unique"	true
-- "btree"	"can_multi_col"	true
-- "btree"	"can_exclude"	true

-- THE PROPERTIES OF INDEX
select 
	p.name, 
	pg_index_has_property('aircrafts_data_range_idx'::regclass, p.name)
from unnest(array['clusterable', 'index_scan', 'bitmap_scan', 'backward_scan']) p(name);
-- "clusterable"	true
-- "index_scan"		true
-- "bitmap_scan"	true
-- "backward_scan"	true

-- THE PROPERTIES OF COLUMNS
select
	p.name,
	pg_index_column_has_property('aircrafts_data_range_idx'::regclass, 1, p.name)
from
	unnest(array['asc', 'desc', 'nulls_first', 'nulls_last', 'orderable', 'distance_orderable', 'returnable', 'search_array', 'search_nulls']) p(name);
-- "asc"				false
-- "desc"				true
-- "nulls_first"		true
-- "nulls_last"			false
-- "orderable"			true
-- "distance_orderable"	false
-- "returnable"			true
-- "search_array"		true
-- "search_nulls"		true

-- THE SEARCH ARRAY PROPERTY
explain (costs off)
select 
	*
from 
	aircrafts
where
	aircraft_code in ('733', '763', '773')
;
-- "Index Scan using aircrafts_pkey on aircrafts_data ml"
-- "  Index Cond: (aircraft_code = ANY ('{733,763,773}'::bpchar[]))"


-- EXPLORING THE INTERNALS OF B-TREE INDEX
drop extension if exists pageinspect;
create extension if not exists pageinspect;

select 
	*
from
	bt_metap('ticket_flights_pkey');
-- magic	version		root level	fastroot	fastlevel	last_cleanup_num_delpages		last_cleanup_num_tuples		allequalimage
-- 340322		4		201		2		201			2					0								-1					true

select
	type,
	live_items,
	dead_items,
	avg_item_size,
	page_size,
	free_size
from
	bt_page_stats('ticket_flights_pkey', 164)
-- "l"	204	0	32	8192 BYTES	804

