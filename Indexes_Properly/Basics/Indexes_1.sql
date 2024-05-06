drop table if exists t;
create table if not exists t(a integer, b text, c boolean);
insert into t (a,b,c)
select 
	s.id,
	chr((32+random()*94)::integer),
	random() < 0.01 
from generate_series(1,100_000) as s(id)
order by random();

select * from t;

-- Index creation
create index on t(a);

explain (costs off)
select * from t where a = 1;
-- "Bitmap Heap Scan on t"
-- "  Recheck Cond: (a = 1)"
-- "  ->  Bitmap Index Scan on t_a_idx"
-- "        Index Cond: (a = 1)"

explain (costs off)
select * from t where a <= 100;
-- "Bitmap Heap Scan on t"
-- "  Recheck Cond: (a <= 100)"
-- "  ->  Bitmap Index Scan on t_a_idx"
-- "        Index Cond: (a <= 100)"

create index on t(b);

analyze t;
explain (costs off)
select * 
from t
where
	a <= 100 and b = 'a';
-- "Bitmap Heap Scan on t"
-- "  Recheck Cond: ((a <= 100) AND (b = 'a'::text))"
-- "  ->  BitmapAnd"
-- "        ->  Bitmap Index Scan on t_a_idx"
-- "              Index Cond: (a <= 100)"
-- "        ->  Bitmap Index Scan on t_b_idx"
-- "              Index Cond: (b = 'a'::text)"

-- While picking method the planner checks the statistics about the fraction of data ordering.
select attname, correlation from pg_stats where tablename = 't';
-- "a"	-0.009674252 because the values are randomly ordered
-- "b"	1 the values is fully ordered in asc order
-- "c"	0.9413841 the data is sorted practically

select * from t;


explain (costs off)
select * from t where a <= 40000;
-- "Seq Scan on t" the selectivity is low, so the planner has chosen the Sequential Scanning
-- "  Filter: (a <= 40000)"

explain (analyze, costs off)
select a from t where a < 100;
-- "Bitmap Heap Scan on t (actual time=0.011..0.050 rows=99 loops=1)"
-- "  Recheck Cond: (a < 100)"
-- "  Heap Blocks: exact=93"
-- "  ->  Bitmap Index Scan on t_a_idx (actual time=0.004..0.004 rows=99 loops=1)"
-- "        Index Cond: (a < 100)"
-- "Planning Time: 0.013 ms"
-- "Execution Time: 0.054 ms"

-- MULTIPLE INDEXES
create index on t(a,b);
analyze t;
explain
select * from t where a <= 100 and b = 'a';
-- "Index Scan using t_a_b_idx on t  (cost=0.29..9.25 rows=1 width=7)"
-- "  Index Cond: ((a <= 100) AND (b = 'a'::text))"

explain (costs off)
select * from t where a <= 100;
-- "Bitmap Heap Scan on t"
-- "  Recheck Cond: (a <= 100)"
-- "  ->  Bitmap Index Scan on t_a_b_idx"
-- "        Index Cond: (a <= 100)"

explain (costs off)
select * from t where lower(b) = 'a'; -- The indexes are applied when we work with " indexed attr + operator + expression  ". Instead of using this, we should
-- use the "functional indexes"
-- "Seq Scan on t"
-- "  Filter: (lower(b) = 'a'::text)"

-- FUNCTIONAL INDEXES
create index on t(lower(b));
analyze t;

explain (costs off)
select *
from t
	where lower(b) = 'a';
-- "Bitmap Heap Scan on t"
-- "  Recheck Cond: (lower(b) = 'a'::text)"
-- "  ->  Bitmap Index Scan on t_lower_idx"
-- "        Index Cond: (lower(b) = 'a'::text)"

select * from pg_stats where tablename = 't_lower_idx';
-- "public"	"t_lower_idx"	"lower"	false	0	5	69	"{x,d,h,y,l,t,q,v,b,i,e,m,j,s,w,u,k,a,n,g,z,p,o,f,r,c,%,5,9,[,#,?,>,0,1,2,6,:,`,$,*,-,""{"",7,""\"""",',8,(,.,@,3,""\\"",),;,<,^,4,],&,""}"","","",+,_,=,|,!,/,"" "",~}"	{0.024066666,0.022533333,0.0224,0.022366667,0.022066666,0.021666666,0.021533333,0.021533333,0.0215,0.0215,0.021433333,0.021333333,0.021133333,0.021033334,0.021,0.020966666,0.020933334,0.020866666,0.020766666,0.0206,0.020533333,0.0205,0.020466667,0.020233333,0.020066667,0.019933334,0.0119,0.0119,0.011666667,0.0115,0.0113,0.011266666,0.011166667,0.011133334,0.011133334,0.011133334,0.011133334,0.011133334,0.0111,0.011033333,0.0109,0.010866666,0.010866666,0.0108,0.010766666,0.010733333,0.0107,0.010633334,0.010633334,0.0106,0.0105,0.010466667,0.010433333,0.010433333,0.010433333,0.010433333,0.010366667,0.0103,0.0101666665,0.010066667,0.010033334,0.009833333,0.009833333,0.0098,0.009533334,0.0092,0.0092,0.005133333,0.0048666666}		0.85985816			


-- PARTIAL INDEXES
create index on t(c);
analyze t;

explain (costs off)
select * from t where c;
-- "Index Scan using t_c_idx on t"
-- "  Index Cond: (c = true)"

explain (costs off)
select * from t where not c;
-- "Seq Scan on t"
-- "  Filter: (NOT c)"

select relpages from pg_class where relname = 't_c_idx';
-- 87 is the number of pages of index on c attr but the 99% of index isn't used because of the most part of table values is false

create index on t(c) where c;
analyze t;

select relpages from pg_class where relname = 't_c_idx1';
-- 2 is the number of pages for the partial index

-- SORTING
set enable_indexscan = off;
explain (analyze, costs off)
select * from t
order by a;
-- "Planning Time: 0.041 ms"
-- "Execution Time: 20.211 ms"

set enable_indexscan = on;
explain (analyze, costs off)
select * from t
order by a;
-- "Planning Time: 0.041 ms"
-- "Execution Time: 17.480 ms"