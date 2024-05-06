-- GiST - generalized search tree is balanced search tree.  GiST is balanced tree by height consists of nodes-pages. Nodes consists of indexes.

-- R-Tree for points
drop table if exists points;
create table if not exists points(p point);

insert into points (p) values (point '(1,1)'), (point '(3,2)'), (point '(6,3)'), (point '(5,5)'), (point '(7,8)'), (point '(8,6)');

drop index if exists points_point_gist_idx;
create index points_point_gist_idx on points using gist(p);

set enable_seqscan = off;

explain (costs off)
select 
	*
from 
	points
where
	p <@ box '(2,1), (7,4)'
;
-- "Index Only Scan using points_point_gist_idx on points"
-- "  Index Cond: (p <@ '(7,4),(2,1)'::box)"

select * from points order by p <-> point '(4,7)' limit 2;
-- "(5,5)"
-- "(7,8)"
-- "(8,6)"
-- "(6,3)"
-- "(3,2)"
-- "(1,1)"
-- The meaning is: give me the neares two points to point (4,7) (k-nn k-nearest neighbor search)

select amop.amopopr::regoperator, amop.amoppurpose,
amop.amopstrategy
from pg_opclass opc, pg_opfamily opf, pg_am am, pg_amop amop
where opc.opcname = 'point_ops'
and opf.oid = opc.opcfamily
and am.oid = opf.opfmethod
and amop.amopfamily = opc.opcfamily
and am.amname = 'gist'
and amop.amoplefttype = opc.opcintype;
-- "<<(point,point)"	"s"	1
-- ">>(point,point)"	"s"	5
-- "~=(point,point)"	"s"	6
-- "<<|(point,point)"	"s"	10
-- "|>>(point,point)"	"s"	11
-- "<->(point,point)"	"o"	15
-- "<^(point,point)"	"s"	29
-- ">^(point,point)"	"s"	30
-- "<@(point,box)"		"s"	28
-- "<@(point,polygon)"	"s"	48
-- "<@(point,circle)"	"s"	68


-- R-Tree for intervals
drop table if exists reservations;
create table if not exists reservations(during tsrange);

insert into reservations (during) 
values
	('[2016-12-30, 2017-01-09)'),
	('[2017-02-23, 2017-02-27)'),	
	('[2017-04-29, 2017-05-02)');

drop index if exists reservations_during_gist_ind;
create index if not exists reservations_during_gist_ind on reservations(during);

select * from reservations where during && '[2017-01-01, 2017-04-01)';
-- "[""2016-12-30 00:00:00"",""2017-01-09 00:00:00"")"
-- "[""2017-02-23 00:00:00"",""2017-02-27 00:00:00"")"

explain (costs off)
select * from reservations where during && '[2017-01-01, 2017-04-01)';
-- "Index Only Scan using reservations_during_gist_ind on reservations"
-- "  Filter: (during && '[""2017-01-01 00:00:00"",""2017-04-01 00:00:00"")'::tsrange)"

select amop.amopopr::regoperator, amop.amoppurpose,
amop.amopstrategy
from pg_opclass opc, pg_opfamily opf, pg_am am, pg_amop amop
where opc.opcname = 'range_ops'
and opf.oid = opc.opcfamily
and am.oid = opf.opfmethod
and amop.amopfamily = opc.opcfamily
and am.amname = 'gist'
and amop.amoplefttype = opc.opcintype;
-- "@>(anyrange,anyelement)"	"s"	16
-- "<<(anyrange,anyrange)"	"s"	1
-- "&<(anyrange,anyrange)"	"s"	2
-- "&&(anyrange,anyrange)"	"s"	3
-- "&>(anyrange,anyrange)"	"s"	4
-- ">>(anyrange,anyrange)"	"s"	5
-- "-|-(anyrange,anyrange)"	"s"	6
-- "@>(anyrange,anyrange)"	"s"	7
-- "<@(anyrange,anyrange)"	"s"	8
-- "=(anyrange,anyrange)"	"s"	18
-- "<<(anyrange,anymultirange)"	"s"	1
-- "&<(anyrange,anymultirange)"	"s"	2
-- "&&(anyrange,anymultirange)"	"s"	3
-- "&>(anyrange,anymultirange)"	"s"	4
-- ">>(anyrange,anymultirange)"	"s"	5
-- "-|-(anyrange,anymultirange)"	"s"	6
-- "@>(anyrange,anymultirange)"	"s"	7
-- "<@(anyrange,anymultirange)"	"s"	8

alter table reservations add exclude using gist(during with &&); -- Now we cannot insert the intervals that cross with each other
-- insert into reservations(during) values ('[2017-05-15, 2017-06-15)');
-- insert into reservations(during) values ('[2017-06-10, 2017-06-15)');
-- ERROR:  conflicting key value violates exclusion constraint "reservations_during_excl"

alter table reservations add column house_no integer default 1;

alter table reservations drop constraint reservations_during_excl;
-- alter table reservations add exclude using gist(during with &&, house_no with =);
-- ERROR:  data type integer has no default operator class for access method "gist"

drop extension if exists btree_gist;
create extension btree_gist;
alter table reservations add exclude using gist(during with &&, house_no with =);
-- ALTER TABLE
insert into reservations(during, house_no) values ('[2017-05-15, 2017-06-15)', 1);
-- insert into reservations(during, house_no) values ('[2017-06-10, 2017-06-15)', 1);
-- conflicting key value violates exclusion constraint "reservations_during_house_no_excl"
insert into reservations(during, house_no) values ('[2017-06-10, 2017-06-15)', 2);
-- INSERT

set default_text_search_config = russian;
select to_tsvector('И встал Айболит, побежал Айболит. По полям, по лесам, по лугам он бежит.');
-- "'айбол':3,5 'беж':13 'встал':2 'лес':9 'луг':11 'побежа':4 'пол':7"

select to_tsquery('Айболит & (побежал | пошел)');
-- "'айбол' & ( 'побежа' | 'пошел' )"

select to_tsvector('И встал Айболит, побежал Айболит.') @@ to_tsquery('Айболит & (побежал | пошел)');
-- true
select to_tsvector('И встал Айболит, побежал Айболит.') @@ to_tsquery('Бармалей & (побежал | пошел)');
-- false

drop table if exists ts;
create table if not exists ts(doc text, doc_tsv tsvector);

drop index if exists ts_doc_tsv_idx;
create index ts_doc_tsv_idx on ts using gist(doc_tsv);

insert into ts(doc) values
('Во поле береза стояла'),  ('Во поле кудрявая стояла'),
 ('Люли, люли, стояла'),
 ('Некому березу заломати'), ('Некому кудряву заломати'),
 ('Люли, люли, заломати'),
 ('Я пойду погуляю'),        ('Белую березу заломаю'),
 ('Люли, люли, заломаю');

update ts set doc_tsv = to_tsvector(doc);
select * from ts;

-- THE METHOD'S PROPERTIES
select 
	a.amname as access_method_name, 
	p.name as property_name, 
	pg_indexam_has_property(a.oid, p.name) as is_property_presented 
from pg_am a,
	unnest(array['can_order', 'can_unique', 'can_multi_col', 'can_exclude']) as p(name)
where 
	a.amname = 'gist'
order by a.amname;
-- "gist"	"can_order"		false
-- "gist"	"can_unique"	false
-- "gist"	"can_multi_col"	true
-- "gist"	"can_exclude"	true

-- THE PROPERTIES OF INDEX
select 
	p.name, 
	pg_index_has_property('points_point_gist_idx'::regclass, p.name)
from unnest(array['clusterable', 'index_scan', 'bitmap_scan', 'backward_scan']) p(name);
-- "clusterable"	true
-- "index_scan"		true
-- "bitmap_scan"	true
-- "backward_scan"	false

-- THE PROPERTIES OF COLUMNS
select
	p.name,
	pg_index_column_has_property('points_point_gist_idx'::regclass, 1, p.name)
from
	unnest(array['asc', 'desc', 'nulls_first', 'nulls_last', 'orderable', 'distance_orderable', 'returnable', 'search_array', 'search_nulls']) p(name);
-- "asc"				false
-- "desc"				false
-- "nulls_first"		false
-- "nulls_last"			false
-- "orderable"			false
-- "distance_orderable"	true is the opportunity to search by k-nn
-- "returnable"			true is the opportunity to use only Index Only Scan
-- "search_array"		false
-- "search_nulls"		true