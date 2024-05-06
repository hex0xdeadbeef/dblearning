-- HASH INDEX

-- CREATION OF HASH INDEX
drop index flights_flight_no_idx;
create index on flights using hash(flight_no);

explain (costs off)
select *
from 
	flights
where
	flight_no = 'PG0001';
-- "Bitmap Heap Scan on flights"
-- "  Recheck Cond: (flight_no = 'PG0001'::bpchar)"
-- "  ->  Bitmap Index Scan on flights_flight_no_idx"
-- "        Index Cond: (flight_no = 'PG0001'::bpchar)"

select
	opf.opfname as opfamily_name,
	amproc.amproc::regproc as opfamily_procedure
from
	pg_am am,
	pg_opfamily opf,
	pg_amproc amproc
where
	opf.opfmethod = am.oid
	and amproc.amprocfamily = opf.oid
	and am.amname = 'hash'
order by opfamily_name, opfamily_procedure;

select hashtext('two');
-- 1590507854 is 2^32 integer number


-- THE HASH ACCESS METHOD'S PROPERTIES
select 
	a.amname as access_method_name, 
	p.name as property_name, 
	pg_indexam_has_property(a.oid, p.name) as is_property_presented 
from pg_am a,
	unnest(array['can_order', 'can_unique', 'can_multi_col', 'can_exclude']) as p(name)
where 
	a.amname = 'hash'
order by a.amname;
-- "hash"	"can_order"	false
-- "hash"	"can_unique"	false
-- "hash"	"can_multi_col"	false
-- "hash"	"can_exclude"	true

-- THE PROPERTIES OF HASH INDEX
select 
	p.name, 
	pg_index_has_property('flights_flight_no_idx'::regclass, p.name)
from unnest(array['clusterable', 'index_scan', 'bitmap_scan', 'backward_scan']) p(name);
-- "clusterable"	false
-- "index_scan"	true
-- "bitmap_scan"	true
-- "backward_scan"	true

-- THE PROPERTIES OF COLUMNS
select
	p.name,
	pg_index_column_has_property('flights_flight_no_idx'::regclass, 1, p.name)
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
-- "search_nulls"	false

select   opf.opfname AS opfamily_name,
         amop.amopopr::regoperator AS opfamily_operator
from     pg_am am,
         pg_opfamily opf,
         pg_amop amop
where    opf.opfmethod = am.oid
and      amop.amopfamily = opf.oid
and      am.amname = 'hash'
order by opfamily_name,
         opfamily_operator;
-- The only one operator of Hash Index is "Equality"
-- "aclitem_ops"	"=(aclitem,aclitem)"
-- "array_ops"	"=(anyarray,anyarray)"
-- "bool_ops"	"=(boolean,boolean)"
-- "bpchar_ops"	"=(character,character)"
-- ...

-- CHECKING THE INTERNALS OF HASH INDEX
drop extension if exists pageinspect;
create extension pageinspect;

select hash_page_type(get_raw_page('flights_flight_no_idx', 0));
-- "metapage"

select
	ntuples,
	maxbucket
from hash_metapage_info(get_raw_page('flights_flight_no_idx', 0));
-- 65664	255

select hash_page_type(get_raw_page('flights_flight_no_idx', 1));
-- "bucket"

select
	live_items,
	dead_items
from
hash_page_stats(get_raw_page('flights_flight_no_idx', 1));
-- 121	0
