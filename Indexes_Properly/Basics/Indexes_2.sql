-- 1. The properties of Index
select amname from pg_am;
-- "heap"
-- "btree"
-- "hash"
-- "gist"
-- "gin"
-- "spgist"
-- "brin"

-- The properties of access method: pg_indexam_has_property
-- The properties of a specific index: pg_index_has_property
-- The properties of the separate columns of index: p_index_column_has_property

amname = 'btree'
order by a.amname;
-- 	"btree"		"can_order"		true
-- 	"btree"		"can_unique"	true
-- 	"btree"		"can_multi_col"	true
-- 	"btree"		"can_exclude"	true

-- The EXCLUDE operator is used to prevent the INSERTION OR UPDATING the rows that violate condition.
-- drop table if exists events;
-- create table if not exists events (
-- 	id serial primary key,
-- 	name varchar (255) not null,
-- 	start_time timestamp not null,
-- 	end_time timestamp not null,
-- 	EXCLUDE using gist(
-- 		-- THE METHOD'S PROPERTIES
select
	a.amname as access_method_name,
	p.name as property_name,
	pg_indexam_has_property(a.oid, p.name) as is_property_presented
from pg_am a,
	unnest(array['can_order', 'can_unique', 'can_multi_col', 'can_exclude']) as p(name)
where
	a.tsrange(start_time, end_time)
-- 	)
-- );


-- THE PROPERTIES OF INDEX
select
	p.name,
	pg_index_has_property('t_a_idx'::regclass, p.name)
from unnest(array['clusterable', 'index_scan', 'bitmap_scan', 'backward_scan']) p(name);
-- "t_a_idx" btree (a)
-- "clusterable"	true
-- "index_scan"	true
-- "bitmap_scan"	true
-- "backward_scan"	true


-- THE PROPERTIES OF COLUMNS
select
	p.name,
	pg_index_column_has_property('t_a_idx'::regclass, 1, p.name)
from
	unnest(array['asc', 'desc', 'nulls_first', 'nulls_last', 'orderable', 'distance_orderable', 'returnable', 'search_array', 'search_nulls']) p(name);
-- "t_a_idx" btree (a)
-- "asc"					true
-- "desc"					false
-- "nulls_first"			false
-- "nulls_last"				true
-- "orderable"				true
-- "distance_orderable"		false
-- "returnable"				true
-- "search_array"			true
-- "search_nulls"			true


-- CLASSES AND FAMILIES OF OPERATORS
-- The class of operators includes the minimal set of operators for index to work with the specific data type

-- The class is always included by the family of operators. By the way, the common family can consists of the several classes if they have the same semantic.
-- For example the family 'integer_ops' includes the classes int8_ops, int4_ops and int2_ops (bigint, integer, smallint)
select
	opfname as operator_family_name,
	opcname as operator_class_name,
	opcintype::regtype
from
	pg_opclass opc,
	pg_opfamily opf
where opf.opfname = 'integer_ops' and opc.opcfamily = opf.oid and opf.opfmethod = (select oid from pg_am where amname = 'btree');
-- "integer_ops"	"int2_ops"	"smallint"
-- "integer_ops"	"int4_ops"	"integer"
-- "integer_ops"	"int8_ops"	"bigint"

select
	opfname,
	opcname,
	opcintype::regtype
from pg_opclass opc, pg_opfamily opf
where opf.opfname = 'datetime_ops' and opc.opcfamily = opf.oid and opf.opfmethod = (select oid from pg_am where amname = 'btree');
-- "datetime_ops"	"date_ops"	"date"
-- "datetime_ops"	"timestamptz_ops"	"timestamp with time zone"
-- "datetime_ops"	"timestamp_ops"	"timestamp without time zone"

explain (costs off) select * from t where b like 'A%';
-- "Seq Scan on t"
-- "  Filter: (b ~~ 'А%'::text)" The usual index on text field doesn't support the LIKE operation

create index on t(b text_pattern_ops);
-- CREATE

explain (costs off) select * from t where b like 'A%';
-- "Bitmap Heap Scan on t"
-- "  Filter: (b ~~ 'A%'::text)"
-- "  ->  Bitmap Index Scan on t_b_idx2"
-- "        Index Cond: ((b ~>=~ 'A'::text) AND (b ~<~ 'B'::text))"