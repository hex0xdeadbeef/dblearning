-- GIN index
-- The GIN index is the index that is used with the values that consist of the other elements. For example: the document where the elements is lexems. 

-- The GIN is b-tree of lists of elements that are unidirectinally linked and the leaves of this tree are bound with b-tree / flat lists of TIDs

-- The GIN index introduces to the developer the interface for supporting diverse operations over aggregate data types.

DROP TABLE IF EXISTS ts;
CREATE TABLE IF NOT EXISTS ts(doc text, doc_tsv tsvector);

INSERT INTO ts(doc) VALUES 
('Во поле береза стояла'),
('Во поле кудрявая стояла'),
('Люли, люли, стояла'),
('Люли, люли, стояла'),
('Некому березу заломати'),
('Некому кудряву заломати'),
('Люли, люли, заломати'),
('Я пойду погуляю'),
('Люли, люли, заломаю'),
('Люли, люли, заломати'),
('Белую березу заломаю'),
('Люли, люли, заломаю');

set default_text_search_config = russian;

update ts set doc_tsv = to_tsvector(doc);

create index ts_doc_tsv_gin_idx on ts using gin(doc_tsv);

select
	ctid,
	doc,
	doc_tsv
from
	ts;
-- "(0,13)"	"Во поле береза стояла"	"'берез':3 'пол':2 'стоя':4"
-- "(0,14)"	"Во поле кудрявая стояла"	"'кудряв':3 'пол':2 'стоя':4"
-- "(0,15)"	"Люли, люли, стояла"	"'люл':1,2 'стоя':3"
-- "(0,16)"	"Люли, люли, стояла"	"'люл':1,2 'стоя':3"
-- "(0,17)"	"Некому березу заломати"	"'берез':2 'заломат':3 'нек':1"
-- "(0,18)"	"Некому кудряву заломати"	"'заломат':3 'кудряв':2 'нек':1"
-- "(0,19)"	"Люли, люли, заломати"	"'заломат':3 'люл':1,2" For 'люл' the b-tree was built
-- "(0,20)"	"Я пойду погуляю"	"'погуля':3 'пойд':2"
-- "(0,21)"	"Люли, люли, заломаю"	"'залома':3 'люл':1,2" For 'люл' the b-tree was built
-- "(0,22)"	"Люли, люли, заломати"	"'заломат':3 'люл':1,2" For 'люл' the b-tree was built
-- "(0,23)"	"Белую березу заломаю"	"'бел':1 'берез':2 'залома':3"
-- "(0,24)"	"Люли, люли, заломаю"	"'залома':3 'люл':1,2" For 'люл' the b-tree was built

select (unnest(doc_tsv)).lexeme as lexeme, count(*) as cnt from ts group by 1 order by 2 desc;
-- "люл"	6
-- "стоя"	4
-- "заломат"	4
-- "берез"	3
-- "залома"	3
-- "пол"	2
-- "нек"	2
-- "кудряв"	2
-- "пойд"	1
-- "погуля"	1
-- "бел"	1

set enable_seqscan = off;

explain (costs off)
select doc from ts where doc_tsv @@ to_tsquery('кудрявая & стояла'); -- The @@ is full-context search


select amop.amopopr::regoperator, amop.amopstrategy
from pg_opclass opc, pg_opfamily opf, pg_am am, pg_amop amop
where opc.opcname = 'tsvector_ops'
and opf.oid = opc.opcfamily
and am.oid = opf.opfmethod
and amop.amopfamily = opc.opcfamily
and am.amname = 'gin'
and amop.amoplefttype = opc.opcintype;
-- "@@(tsvector,tsquery)"	1
-- "@@@(tsvector,tsquery)"	2

select doc from ts where doc_tsv @@ to_tsquery('кудрявая & стояла'); -- The @@ is full-context search
-- "Во поле кудрявая стояла"

drop index if exists ts_doc_tsv_gin_idx;
create index ts_doc_tsv_gin_fast_idx on ts using gin(doc_tsv) with (fastupdate = true);
-- CREATE


-- Partial match in full-context search
select doc from ts where doc_tsv @@ to_tsquery('залом:*');
-- "Некому березу заломати"
-- "Некому кудряву заломати"
-- "Люли, люли, заломати"
-- "Люли, люли, заломаю"
-- "Люли, люли, заломати"
-- "Белую березу заломаю"
-- "Люли, люли, заломаю"

explain (costs off)
select doc from ts where doc_tsv @@ to_tsquery('залом:*');

-- WORKING WITH THE LARGE ARRAY OF DATA THE unnest won't work, so we use the ts_stat('...'), where '...' is the query
select 
 	word,
	ndoc
	from ts_stat('select doc_tsv from ts')
order by ndoc desc limit 3;
-- "люл"	6
-- "стоя"	4
-- "заломат"	4

select 
 	word,
	ndoc
	from ts_stat('select doc_tsv from ts')
where word = 'стоя';
-- "стоя"	4

-- Is there the docs where some lexems is presented simultaneously
select count(*) as cnt from ts where doc_tsv @@ to_tsquery('некому & заломати');
-- 2
-- 28 ms

select count(*) as cnt from ts where doc_tsv @@ to_tsquery('белую');
-- 1
-- 37 ms

-- Using limit with GIN idex isn't profitable because the GIN index isn't possible to throw TIDs one by one. (It uses Bitmap Scan and throws the bitmap)
-- The GIN index has the parameter that's called "gin_fuzzy_search_limit" that constrains the rows will be output;
set gin_fuzzy_search_limit = 100000;

select count(*) from ts where doc_tsv @@ to_tsquery('люли');


-- GIN index with arrays
select amop.amopopr::regoperator, amop.amopstrategy
from pg_opclass opc, pg_opfamily opf, pg_am am, pg_amop amop
where opc.opcname = 'array_ops'
and opf.oid = opc.opcfamily
and am.oid = opf.opfmethod
and amop.amopfamily = opc.opcfamily
and am.amname = 'gin'
and amop.amoplefttype = opc.opcintype;
-- "&&(anyarray,anyarray)"	1
-- "@>(anyarray,anyarray)"	2
-- "<@(anyarray,anyarray)"	3
-- "=(anyarray,anyarray)"	4

select * from routes;
select 
	departure_airport_name, 
	arrival_airport_name, 
	days_of_week
from
	routes
where
	flight_no = 'PG0049';
-- "Внуково"	"Геленджик"	{2,5,7}

drop table if exists routes_t;
create table routes_t as select * from routes;

drop index if exists routes_t_days_of_week_gin_idx;
create index routes_t_days_of_week_gin_idx on routes_t using gin(days_of_week);
-- CREATE

explain (costs off)
select count(*) as cnt from routes_t where days_of_week @> array[7];
-- "Aggregate"
-- "  ->  Bitmap Heap Scan on routes_t"
-- "        Recheck Cond: (days_of_week @> '{7}'::integer[])"
-- "        ->  Bitmap Index Scan on routes_t_days_of_week_gin_idx"
-- "              Index Cond: (days_of_week @> '{7}'::integer[])"

select count(*) as cnt from routes_t where days_of_week @> array[7];
-- 558


explain (costs off)
select count(*) as cnt from routes_t where days_of_week @> array[7] and departure_city = 'Москва';
-- "Aggregate"
-- "  ->  Bitmap Heap Scan on routes_t"
-- "        Recheck Cond: (days_of_week @> '{7}'::integer[])"
-- "        Filter: (departure_city = 'Москва'::text)"
-- "        ->  Bitmap Index Scan on routes_t_days_of_week_gin_idx"
-- "              Index Cond: (days_of_week @> '{7}'::integer[])"

select count(*) as cnt from routes_t where days_of_week @> array[7] and departure_city = 'Москва';
-- 134

-- drop index if exists routes_t_days_of_week_departure_city_gin_idx;
-- create index routes_t_days_of_week_departure_city_gin_idx on routes_t using gin(days_of_week, departure_city);
-- ERROR:  data type text has no default operator class for access method "gin"

drop extension if exists btree_gin;
create extension btree_gin;
drop index if exists routes_t_days_of_week_departure_city_gin_idx;
create index routes_t_days_of_week_departure_city_gin_idx on routes_t using gin(days_of_week, departure_city);
-- CREATE INDEX

explain (costs off)
select * from routes_t where days_of_week = array[2,4,7] and departure_city = 'Москва';
-- "Bitmap Heap Scan on routes_t"
-- "  Recheck Cond: ((days_of_week = '{2,4,7}'::integer[]) AND (departure_city = 'Москва'::text))"
-- "  ->  Bitmap Index Scan on routes_t_days_of_week_departure_city_gin_idx"
-- "        Index Cond: ((days_of_week = '{2,4,7}'::integer[]) AND (departure_city = 'Москва'::text))"


select opc.opcname, amop.amopopr::regoperator,
amop.amopstrategy as str
from pg_opclass opc, pg_opfamily opf, pg_am am, pg_amop amop
where opc.opcname in ('jsonb_ops','jsonb_path_ops')
and opf.oid = opc.opcfamily
and am.oid = opf.opfmethod
and amop.amopfamily = opc.opcfamily
and am.amname = 'gin'
and amop.amoplefttype = opc.opcintype;
-- "jsonb_ops"	"?(jsonb,text)"	9
-- "jsonb_ops"	"?|(jsonb,text[])"	10
-- "jsonb_ops"	"?&(jsonb,text[])"	11
-- "jsonb_ops"	"@>(jsonb,jsonb)"	7
-- "jsonb_ops"	"@?(jsonb,jsonpath)"	15
-- "jsonb_ops"	"@@(jsonb,jsonpath)"	16
-- "jsonb_path_ops"	"@>(jsonb,jsonb)"	7
-- "jsonb_path_ops"	"@?(jsonb,jsonpath)"	15
-- "jsonb_path_ops"	"@@(jsonb,jsonpath)"	16


-- GIN with jsonb type
drop table if exists routes_jsonb;
create table routes_jsonb as
select
	to_jsonb(t) as route
from
	(
		select
			departure_airport_name,
			arrival_airport_name,
			days_of_week
		from 
			routes
		order by flight_no limit 4
	) as t;

select 
	ctid,
	jsonb_pretty(route)
from
	routes_jsonb;
-- "(0,1)"	"{""departure_airport_name"":""Усть-Илимск"",""arrival_airport_name"":""Сургут"",""days_of_week"":[6]}"
-- "(0,2)"	"{""departure_airport_name"":""Сургут"",""arrival_airport_name"":""Усть-Илимск"",""days_of_week"":[7]}"
-- "(0,3)"	"{""departure_airport_name"":""Иваново-Южный"",""arrival_airport_name"":""Сочи"",""days_of_week"":[2,6]}"
-- "(0,4)"	"{""departure_airport_name"":""Сочи"",""arrival_airport_name"":""Иваново-Южный"",""days_of_week"":[3,7]}"

explain (costs off)
select
	jsonb_pretty(route)
from 
	routes_jsonb
where
	route @> '{"days_of_week":[5]}';
-- "Seq Scan on routes_jsonb"
-- "  Filter: (route @> '{""days_of_week"": [5]}'::jsonb)"
-- IDK why the index hasn't been applied here

select route from routes_jsonb where route @> '{"days_of_week":[6]}';
-- "{""days_of_week"": [6], ""arrival_airport_name"": ""Сургут"", ""departure_airport_name"": ""Усть-Илимск""}"
-- "{""days_of_week"": [2, 6], ""arrival_airport_name"": ""Сочи"", ""departure_airport_name"": ""Иваново-Южный""}"


-- THE METHOD'S PROPERTIES
select 
	a.amname as access_method_name, 
	p.name as property_name, 
	pg_indexam_has_property(a.oid, p.name) as is_property_presented 
from pg_am a,
	unnest(array['can_order', 'can_unique', 'can_multi_col', 'can_exclude']) as p(name)
where 
	a.amname = 'gin'
order by a.amname;
-- "gin"	"can_order"		false
-- "gin"	"can_unique"	false
-- "gin"	"can_multi_col"	true
-- "gin"	"can_exclude"	false

-- THE PROPERTIES OF INDEX
select 
	p.name, 
	pg_index_has_property('routes_t_days_of_week_gin_idx'::regclass, p.name)
from unnest(array['clusterable', 'index_scan', 'bitmap_scan', 'backward_scan']) p(name);
-- "clusterable"	false
-- "index_scan"		false
-- "bitmap_scan"	true
-- "backward_scan"	false

-- THE PROPERTIES OF COLUMNS
select
	p.name,
	pg_index_column_has_property('routes_t_days_of_week_gin_idx'::regclass, 1, p.name)
from
	unnest(array['asc', 'desc', 'nulls_first', 'nulls_last', 'orderable', 'distance_orderable', 'returnable', 'search_array', 'search_nulls']) p(name);
-- "asc"				false
-- "desc"				false
-- "nulls_first"		false
-- "nulls_last"			false
-- "orderable"			false
-- "distance_orderable"	false
-- "returnable"			false
-- "search_array"		false
-- "search_nulls"		false