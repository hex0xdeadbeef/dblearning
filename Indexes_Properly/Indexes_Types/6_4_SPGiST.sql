-- SP-GiST (Space Partitioning)
drop table if exists points;
create table if not exists points (p point);

insert into points (p) values 
	(point '(1,1)'), (point '(3,2)'), (point '(6,3)'),
   (point '(5,5)'), (point '(7,8)'), (point '(8,6)');

drop index if exists points_p_spgist;
create index points_p_spgist on points using spgist(p);
-- In this case the pg uses the quad_point_ops as a default

select amop.amopopr::regoperator, amop.amopstrategy
from pg_opclass opc, pg_opfamily opf, pg_am am, pg_amop amop
where opc.opcname = 'quad_point_ops'
and opf.oid = opc.opcfamily
and am.oid = opf.opfmethod
and amop.amopfamily = opc.opcfamily
and am.amname = 'spgist'
and amop.amoplefttype = opc.opcintype;
-- "<<(point,point)"	1
-- ">>(point,point)"	5
-- "~=(point,point)"	6
-- "<<|(point,point)"	10
-- "|>>(point,point)"	11
-- "<->(point,point)"	15
-- "<^(point,point)"	29
-- ">^(point,point)"	30
-- "<@(point,box)"		8

select * from points where p >^ point '(2,7)';
-- "(7,8)"

set enable_seqscan = off;

explain (costs off)
select * from points where p >^ point '(2,7)';
-- "Index Only Scan using points_p_spgist on points"
-- "  Index Cond: (p >^ '(2,7)'::point)"
	
-- k-D TREES
drop index if exists pooints_kd_idx;
create index pooints_kd_idx on points using spgist(p kd_point_ops);
-- "<<(point,point)"	1
-- ">>(point,point)"	5
-- "~=(point,point)"	6
-- "<<|(point,point)"	10
-- "|>>(point,point)"	11
-- "<->(point,point)"	15
-- "<^(point,point)"	29
-- ">^(point,point)"	30
-- "<@(point,box)"		8


-- RADIX TREE
drop table if exists sites;
create table if not exists sites(url text);
insert into sites (url) values ('postgrespro.ru') ,('postgrespro.com'), ('postgressql.org'),('planet.postgressql.org');

drop index if exists sites_url_idx;
create index sites_url_idx on sites using spgist(url);

select amop.amopopr::regoperator, amop.amopstrategy
from pg_opclass opc, pg_opfamily opf, pg_am am, pg_amop amop
where opc.opcname = 'text_ops'
and opf.oid = opc.opcfamily
and am.oid = opf.opfmethod
and amop.amopfamily = opc.opcfamily
and am.amname = 'spgist'
and amop.amoplefttype = opc.opcintype;
-- "~<~(text,text)"	1
-- "~<=~(text,text)"	2
-- "=(text,text)"	3
-- "~>=~(text,text)"	4
-- "~>~(text,text)"	5
-- "<(text,text)"	11
-- "<=(text,text)"	12
-- ">=(text,text)"	14
-- ">(text,text)"	15
-- "^@(text,text)"	28

select * from sites where url like 'postgresp%ru';
-- "postgrespro.ru"

explain (costs off)
select * from sites where url like 'postgresp%ru';
-- "Index Only Scan using sites_url_idx on sites"
-- "  Index Cond: (url ^@ 'postgresp'::text)"
-- "  Filter: (url ~~ 'postgresp%ru'::text)"

-- THE METHOD'S PROPERTIES
select 
	a.amname as access_method_name, 
	p.name as property_name, 
	pg_indexam_has_property(a.oid, p.name) as is_property_presented 
from pg_am a,
	unnest(array['can_order', 'can_unique', 'can_multi_col', 'can_exclude']) as p(name)
where 
	a.amname = 'spgist'
order by a.amname;
-- "spgist"	"can_order"	false
-- "spgist"	"can_unique"	false
-- "spgist"	"can_multi_col"	false
-- "spgist"	"can_exclude"	true


select 
	p.name, 
	pg_index_has_property('sites_url_idx'::regclass, p.name)
from unnest(array['clusterable', 'index_scan', 'bitmap_scan', 'backward_scan']) p(name);
-- "clusterable"	false
-- "index_scan"		true
-- "bitmap_scan"	true
-- "backward_scan"	false

-- THE PROPERTIES OF COLUMNS
select
	p.name,
	pg_index_column_has_property('sites_url_idx'::regclass, 1, p.name)
from
	unnest(array['asc', 'desc', 'nulls_first', 'nulls_last', 'orderable', 'distance_orderable', 'returnable', 'search_array', 'search_nulls']) p(name);
-- "asc"				false
-- "desc"				false
-- "nulls_first"		false
-- "nulls_last"			false
-- "orderable"			false
-- "distance_orderable"	false
-- "returnable"			true
-- "search_array"		false
-- "search_nulls"		true

explain (costs off)
select * from sites where url is null;
-- "Index Only Scan using sites_url_idx on sites"
-- "  Index Cond: (url IS NULL)"