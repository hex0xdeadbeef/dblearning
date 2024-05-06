-- BRIN (Block Range INdex)
-- BRIN index is aimed to prevent checking the rows that aren't needed to be checked.

-- Internals
-- 1. The metadata page
-- 2. There are the pages of summary information about zones with the indentation.
-- There is the (reverse range map (revmap)) Between the 1) and 2). It's just an array of pointers (TIDs) to the corresponding rows.

-- Index scanning
-- The method builds the bitmap. Sequentially the zone map is beign checked, the indexed rows with the summary info about every zone are identified with pointers.
-- If the zone doesn't contain the value is beign found, it'll be skipped. If the zone might contain the value - all the pages are added to the bitmap.

drop index if exists flights_scheduled_departure_brin_idx;
create index flights_scheduled_departure_brin_idx on flights using brin(scheduled_departure);

analyze flights;
select
	attname,
	correlation
from 
	pg_stats
where
	tablename = 'flights'
order by 2 desc;
-- "flight_id"	0.99926823
-- "status"	0.615968
-- "aircraft_code"	0.3166027
-- "flight_no"	0.09496442
-- "arrival_airport"	0.08352481
-- "scheduled_arrival"	0.0011302511
-- "scheduled_departure"	0.00095109415 IS IDEAL TO BE USED IN BRIN INDEX (is ordered asc/desc)
-- "actual_arrival"	-0.00096859277
-- "actual_departure"	-0.0009792194

-- THE METHOD'S PROPERTIES
select 
	a.amname as access_method_name, 
	p.name as property_name, 
	pg_indexam_has_property(a.oid, p.name) as is_property_presented 
from pg_am a,
	unnest(array['can_order', 'can_unique', 'can_multi_col', 'can_exclude']) as p(name)
where 
	a.amname = 'brin'
order by a.amname;
-- "brin"	"can_order"		false
-- "brin"	"can_unique"	false
-- "brin"	"can_multi_col"	true
-- "brin"	"can_exclude"	false


-- THE PROPERTIES OF INDEX
select 
	p.name, 
	pg_index_has_property('flights_scheduled_departure_brin_idx'::regclass, p.name)
from unnest(array['clusterable', 'index_scan', 'bitmap_scan', 'backward_scan']) p(name);
-- "clusterable"	false
-- "index_scan"	false
-- "bitmap_scan"	true
-- "backward_scan"	false


-- THE PROPERTIES OF COLUMNS
select
	p.name,
	pg_index_column_has_property('flights_scheduled_departure_brin_idx'::regclass, 1, p.name)
from
	unnest(array['asc', 'desc', 'nulls_first', 'nulls_last', 'orderable', 'distance_orderable', 'returnable', 'search_array', 'search_nulls']) p(name);
-- "asc"	false
-- "desc"	false
-- "nulls_first"	false
-- "nulls_last"	false
-- "orderable"	false
-- "distance_orderable"	false
-- "returnable"	false
-- "search_array"	false
-- "search_nulls"	true
