-- -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -- -- set enable_hashjoin = default;
-- -- -- set enable_mergejoin = default;
-- -- -- set enable_nestloop = default;
-- -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- -- 1.

-- -- analyze bookings;
-- explain
-- select *
-- from bookings
-- order by book_ref;
-- -- "Index Scan using bookings_pkey on bookings  (cost=0.42..8549.24 rows=262788 width=21)"


-- -- 2.
-- explain (analyze)
-- select *
-- from bookings
-- order by 1,2;
-- -- "Incremental Sort  (cost=0.47..20374.70 rows=262788 width=21) (actual time=0.130..124.886 rows=262788 loops=1)"
-- -- "  Sort Key: book_ref, book_date"
-- -- "  Presorted Key: book_ref" 
-- -- "  Full-sort Groups: 8213  Sort Method: quicksort  Average Memory: 26kB  Peak Memory: 26kB"
-- -- "  ->  Index Scan using bookings_pkey on bookings  (cost=0.42..8549.24 rows=262788 width=21) (actual time=0.018..16.600 rows=262788 loops=1)"
-- -- "Planning Time: 0.079 ms"
-- -- "Execution Time: 130.028 ms"


-- -- 3.
-- explain (analyze)
-- with sorted_bookings as (
-- 	select * from bookings where total_amount < 100000 order by total_amount
-- )
-- select * from sorted_bookings where total_amount > 50000;
-- -- "Sort  (cost=12178.39..12378.66 rows=80107 width=21) (actual time=32.572..37.134 rows=79690 loops=1)"
-- -- "  Sort Key: bookings.total_amount"
-- -- "  Sort Method: external merge  Disk: 2584kB"
-- -- "  ->  Seq Scan on bookings  (cost=0.00..5653.82 rows=80107 width=21) (actual time=0.004..17.597 rows=79690 loops=1)"
-- -- "        Filter: ((total_amount < '100000'::numeric) AND (total_amount > '50000'::numeric))"
-- -- "        Rows Removed by Filter: 183098"
-- -- "Planning Time: 0.078 ms"
-- -- "Execution Time: 38.858 ms"


-- -- 4.
-- explain
-- select 
-- 	total_amount
-- from bookings
-- order by total_amount desc
-- limit 5;
-- -- "Limit  (cost=6825.36..6825.93 rows=5 width=6)"
-- -- "  ->  Gather Merge  (cost=6825.36..24602.17 rows=154581 width=6)"
-- -- "        Workers Planned: 1"
-- -- "        ->  Sort  (cost=5825.35..6211.80 rows=154581 width=6)"
-- -- "              Sort Key: total_amount DESC"
-- -- "              >  Parallel Seq Scan on bookings  (cost=0.00..3257.81 rows=154581 width=6)"


-- -- 5.
-- explain
-- select
-- 	city,
-- 	count(*)
-- from airports_data
-- group by city
-- having count(*) > 1;
-- -- "HashAggregate  (cost=4.56..5.82 rows=34 width=57)"
-- -- "  Group Key: city"
-- -- "  Filter: (count(*) > 1)"
-- -- "  ->  Seq Scan on airports_data  (cost=0.00..4.04 rows=104 width=49)"


-- -- 6.
-- explain (analyze)
-- select
-- 	*,
-- 	avg(range) over (partition by left(model ->> 'en', strpos(model ->> 'en', ' ') - 1 ))
-- from aircrafts_data;
-- -- "WindowAgg  (cost=1.35..1.62 rows=9 width=136) (actual time=0.030..0.033 rows=9 loops=1)"
-- -- "  ->  Sort  (cost=1.35..1.37 rows=9 width=104) (actual time=0.023..0.023 rows=9 loops=1)"
-- -- "        Sort Key: (""left""((model ->> 'en'::text), (strpos((model ->> 'en'::text), ' '::text) - 1)))"
-- -- "        Sort Method: quicksort  Memory: 25kB"
-- -- "        ->  Seq Scan on aircrafts_data  (cost=0.00..1.20 rows=9 width=104) (actual time=0.010..0.012 rows=9 loops=1)"
-- -- "Planning Time: 0.018 ms"
-- -- "Execution Time: 0.046 ms"

-- -- 7.
-- begin;
-- explain
-- delete from aircrafts_data where model ->> 'en' ilike 'airb%';
-- -- "Delete on aircrafts_data  (cost=0.00..1.14 rows=0 width=0)"
-- -- "  ->  Seq Scan on aircrafts_data  (cost=0.00..1.14 rows=1 width=6)"
-- -- "        Filter: ((model ->> 'en'::text) ~~* 'airb%'::text)"
-- rollback;

-- begin;
-- explain
-- update aircrafts_data set range = 1500 where model ->> 'en' ilike 'air%';
-- "Update on aircrafts_data  (cost=0.00..1.14 rows=0 width=0)"
-- "  ->  Seq Scan on aircrafts_data  (cost=0.00..1.14 rows=1 width=10)"
-- "        Filter: ((model ->> 'en'::text) ~~* 'air%'::text)"
-- rollback;


-- -- 8.
-- explain (analyze)
-- select 
-- 	a.aircraft_code as a_code,
-- 	a.model,
-- 	(select count(r.aircraft_code) from routes r where r.aircraft_code = a.aircraft_code) as num_routes
-- from aircrafts_data as a 
-- group by 1,2
-- order by 3 desc;
-- -- "Sort  (cost=11590.76..11590.78 rows=9 width=76) (actual time=101.456..101.458 rows=9 loops=1)"
-- -- "  Sort Key: ((SubPlan 1)) DESC"
-- -- "  Sort Method: quicksort  Memory: 25kB"
-- -- "  ->  Group  (cost=0.14..11590.62 rows=9 width=76) (actual time=15.521..101.440 rows=9 loops=1)"
-- -- "        Group Key: a.aircraft_code"
-- -- "        ->  Index Scan using aircrafts_pkey on aircrafts_data a  (cost=0.14..12.27 rows=9 width=68) (actual time=0.008..0.038 rows=9 loops=1)"
-- -- "        SubPlan 1"
-- -- "          ->  Aggregate  (cost=1286.47..1286.48 rows=1 width=8) (actual time=11.263..11.263 rows=1 loops=9)"
-- -- "                ->  Hash Join  (cost=1106.81..1285.26 rows=97 width=240) (actual time=10.801..11.259 rows=79 loops=9)"
-- -- "                      Hash Cond: (flights.arrival_airport = ml_1.airport_code)"
-- -- "                      ->  Hash Join  (cost=1101.47..1279.42 rows=187 width=8) (actual time=10.795..11.243 rows=79 loops=9)"
-- -- "                            Hash Cond: (flights.departure_airport = ml.airport_code)"
-- -- "                            ->  GroupAggregate  (cost=1096.13..1269.52 rows=359 width=67) (actual time=10.790..11.227 rows=79 loops=9)"
-- -- "                                  Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, ((flights.scheduled_arrival - flights.scheduled_departure))"
-- -- "                                  ->  Group  (cost=1096.13..1194.13 rows=3590 width=39) (actual time=10.780..11.184 rows=422 loops=9)"
-- -- "                                        Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, ((flights.scheduled_arrival - flights.scheduled_departure)), ((to_char(flights.scheduled_departure, 'ID'::text))::integer)"
-- -- "                                        ->  Sort  (cost=1096.13..1106.48 rows=4140 width=39) (actual time=10.767..10.856 rows=3680 loops=9)"
-- -- "                                              Sort Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, ((flights.scheduled_arrival - flights.scheduled_departure)), ((to_char(flights.scheduled_departure, 'ID'::text))::integer)"
-- -- "                                              Sort Method: quicksort  Memory: 916kB"
-- -- "                                              ->  Seq Scan on flights  (cost=0.00..847.41 rows=4140 width=39) (actual time=0.950..4.615 rows=3680 loops=9)"
-- -- "                                                    Filter: (aircraft_code = a.aircraft_code)"
-- -- "                                                    Rows Removed by Filter: 29441"
-- -- "                            ->  Hash  (cost=4.04..4.04 rows=104 width=4) (actual time=0.024..0.024 rows=104 loops=1)"
-- -- "                                  Buckets: 1024  Batches: 1  Memory Usage: 12kB"
-- -- "                                  ->  Seq Scan on airports_data ml  (cost=0.00..4.04 rows=104 width=4) (actual time=0.002..0.012 rows=104 loops=1)"
-- -- "                      ->  Hash  (cost=4.04..4.04 rows=104 width=4) (actual time=0.034..0.034 rows=104 loops=1)"
-- -- "                            Buckets: 1024  Batches: 1  Memory Usage: 12kB"
-- -- "                            ->  Seq Scan on airports_data ml_1  (cost=0.00..4.04 rows=104 width=4) (actual time=0.005..0.019 rows=104 loops=1)"
-- -- "Planning Time: 0.688 ms"
-- -- "Execution Time: 101.518 ms"

-- explain analyze
-- select
-- 	a.aircraft_code,
-- 	a.model,
-- 	count(r.aircraft_code) as num_routes
-- from aircrafts_data a left join routes r on r.aircraft_code = a.aircraft_code
-- group by 1,2
-- order by 3;
-- -- "Sort  (cost=2731.79..2731.81 rows=9 width=76) (actual time=25.894..25.897 rows=9 loops=1)"
-- -- "  Sort Key: (count(flights.aircraft_code))"
-- -- "  Sort Method: quicksort  Memory: 25kB"
-- -- "  ->  GroupAggregate  (cost=2731.47..2731.65 rows=9 width=76) (actual time=25.850..25.893 rows=9 loops=1)"
-- -- "        Group Key: a.aircraft_code"
-- -- "        ->  Sort  (cost=2731.47..2731.50 rows=12 width=72) (actual time=25.844..25.859 rows=711 loops=1)"
-- -- "              Sort Key: a.aircraft_code"
-- -- "              Sort Method: quicksort  Memory: 98kB"
-- -- "              ->  Hash Right Join  (cost=2447.75..2731.25 rows=12 width=72) (actual time=24.937..25.665 rows=711 loops=1)"
-- -- "                    Hash Cond: (flights.aircraft_code = a.aircraft_code)"
-- -- "                    ->  Hash Join  (cost=2446.55..2726.55 rows=276 width=240) (actual time=24.926..25.587 rows=710 loops=1)"
-- -- "                          Hash Cond: (flights.arrival_airport = ml_1.airport_code)"
-- -- "                          ->  Hash Join  (cost=2441.21..2719.78 rows=531 width=8) (actual time=24.908..25.501 rows=710 loops=1)"
-- -- "                                Hash Cond: (flights.departure_airport = ml.airport_code)"
-- -- "                                ->  GroupAggregate  (cost=2435.87..2701.49 rows=1022 width=67) (actual time=24.892..25.422 rows=710 loops=1)"
-- -- "                                      Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure))"
-- -- "                                      ->  Sort  (cost=2435.87..2461.41 rows=10216 width=39) (actual time=24.885..24.969 rows=3798 loops=1)"
-- -- "                                            Sort Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure)), ((to_char(flights.scheduled_departure, 'ID'::text))::integer)"
-- -- "                                            Sort Method: quicksort  Memory: 364kB"
-- -- "                                            ->  HashAggregate  (cost=1551.24..1755.56 rows=10216 width=39) (actual time=12.274..12.632 rows=3798 loops=1)"
-- -- "                                                  Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, (flights.scheduled_arrival - flights.scheduled_departure), (to_char(flights.scheduled_departure, 'ID'::text))::integer"
-- -- "                                                  Batches: 1  Memory Usage: 913kB"
-- -- "                                                  ->  Seq Scan on flights  (cost=0.00..1054.42 rows=33121 width=39) (actual time=0.005..6.238 rows=33121 loops=1)"
-- -- "                                ->  Hash  (cost=4.04..4.04 rows=104 width=4) (actual time=0.010..0.010 rows=104 loops=1)"
-- -- "                                      Buckets: 1024  Batches: 1  Memory Usage: 12kB"
-- -- "                                      ->  Seq Scan on airports_data ml  (cost=0.00..4.04 rows=104 width=4) (actual time=0.001..0.005 rows=104 loops=1)"
-- -- "                          ->  Hash  (cost=4.04..4.04 rows=104 width=4) (actual time=0.014..0.014 rows=104 loops=1)"
-- -- "                                Buckets: 1024  Batches: 1  Memory Usage: 12kB"
-- -- "                                ->  Seq Scan on airports_data ml_1  (cost=0.00..4.04 rows=104 width=4) (actual time=0.003..0.009 rows=104 loops=1)"
-- -- "                    ->  Hash  (cost=1.09..1.09 rows=9 width=68) (actual time=0.007..0.007 rows=9 loops=1)"
-- -- "                          Buckets: 1024  Batches: 1  Memory Usage: 9kB"
-- -- "                          ->  Seq Scan on aircrafts_data a  (cost=0.00..1.09 rows=9 width=68) (actual time=0.004..0.005 rows=9 loops=1)"
-- -- "Planning Time: 0.200 ms"
-- -- "Execution Time: 26.205 ms"

-- -- 10.
-- explain analyze
-- select * from routes;

-- -- "Planning Time: 0.233 ms"
-- -- "Execution Time: 28.230 ms"

-- copy (select * from routes) to '/Users/dmitriymamykin/Desktop/text.txt' with (format text);


-- -- 11. 
-- explain analyze
-- select
-- 	b.book_ref,
-- 	sum(tf.amount)
-- from bookings b, tickets t, ticket_flights tf
-- where b.book_ref = t.book_ref and t.ticket_no = tf.ticket_no
-- group by 1
-- order by 1;
-- -- "Planning Time: 0.484 ms"
-- -- "Execution Time: 2638.082 ms"

-- explain analyze
-- select 
-- 	book_ref,
-- 	total_amount
-- from bookings
-- order by 1;
-- -- "Planning Time: 0.031 ms"
-- -- "Execution Time: 21.653 ms"


-- -- 11.
-- drop table if exists flights_tmp;
-- create temp table if not exists flights_tmp as select * from flights_v;

-- explain analyze
-- select * from flights_v;
-- -- "Planning Time: 0.305 ms"
-- -- "Execution Time: 79.815 ms"

-- explain analyze
-- select * from flights_tmp;
-- -- "Planning Time: 0.059 ms"
-- -- "Execution Time: 2.125 ms"

-- -- 12.
-- explain analyze
-- select
-- 	count (*)
-- from tickets
-- where passenger_name = 'IVAN IVANOV';
-- -- "Planning Time: 0.102 ms"
-- -- "Execution Time: 25.143 ms"

-- drop index if exists passenger_name_idx;
-- create index passenger_name_idx on tickets (passenger_name);
-- explain analyze
-- select
-- 	count (*)
-- from tickets
-- where passenger_name = 'IVAN IVANOV';
-- -- "Aggregate  (cost=9.08..9.09 rows=1 width=8) (actual time=0.037..0.037 rows=1 loops=1)"
-- -- "  ->  Index Only Scan using passenger_name_idx on tickets  (cost=0.42..9.00 rows=33 width=0) (actual time=0.025..0.030 rows=200 loops=1)"
-- -- "        Index Cond: (passenger_name = 'IVAN IVANOV'::text)"
-- -- "        Heap Fetches: 0"
-- -- "Planning Time: 0.091 ms"
-- -- "Execution Time: 0.046 ms"


-- -- 13.
-- set enable_hashjoin = on;
-- set enable_mergejoin = off;
-- set enable_nestloop = off;

-- -- "GroupAggregate  (cost=13003.98..13015.83 rows=200 width=16) (actual time=24.851..26.688 rows=0 loops=1)"
-- -- "  Group Key: count_tickets.num_tickets"
-- -- "  ->  Sort  (cost=13003.98..13007.26 rows=1314 width=8) (actual time=24.850..26.687 rows=0 loops=1)"
-- -- "        Sort Key: count_tickets.num_tickets DESC"
-- -- "        Sort Method: quicksort  Memory: 25kB"
-- -- "        ->  Subquery Scan on count_tickets  (cost=12712.25..12935.91 rows=1314 width=8) (actual time=24.846..26.683 rows=0 loops=1)"
-- -- "              ->  Finalize GroupAggregate  (cost=12712.25..12922.77 rows=1314 width=15) (actual time=24.845..26.681 rows=0 loops=1)"
-- -- "                    Group Key: b.book_ref"
-- -- "                    ->  Gather Merge  (cost=12712.25..12901.99 rows=1528 width=15) (actual time=24.844..26.679 rows=0 loops=1)"
-- -- "                          Workers Planned: 2"
-- -- "                          Workers Launched: 2"
-- -- "                          ->  Partial GroupAggregate  (cost=11712.23..11725.60 rows=764 width=15) (actual time=21.265..21.269 rows=0 loops=3)"
-- -- "                                Group Key: b.book_ref"
-- -- "                                ->  Sort  (cost=11712.23..11714.14 rows=764 width=7) (actual time=21.264..21.267 rows=0 loops=3)"
-- -- "                                      Sort Key: b.book_ref"
-- -- "                                      Sort Method: quicksort  Memory: 25kB"
-- -- "                                      Worker 0:  Sort Method: quicksort  Memory: 25kB"
-- -- "                                      Worker 1:  Sort Method: quicksort  Memory: 25kB"
-- -- "                                      ->  Parallel Hash Join  (cost=4040.80..11675.65 rows=764 width=7) (actual time=21.209..21.212 rows=0 loops=3)"
-- -- "                                            Hash Cond: (t.book_ref = b.book_ref)"
-- -- "                                            ->  Parallel Index Only Scan using tickets_book_ref_idx on tickets t  (cost=0.42..7234.14 rows=152805 width=7) (never executed)"
-- -- "                                                  Heap Fetches: 0"
-- -- "                                            ->  Parallel Hash  (cost=4030.72..4030.72 rows=773 width=7) (actual time=21.172..21.173 rows=0 loops=3)"
-- -- "                                                  Buckets: 2048  Batches: 1  Memory Usage: 0kB"
-- -- "                                                  ->  Parallel Seq Scan on bookings b  (cost=0.00..4030.72 rows=773 width=7) (actual time=21.118..21.118 rows=0 loops=3)"
-- -- "                                                        Filter: (date_trunc('mon'::text, book_date) = '2016-09-01 00:00:00+04'::timestamp with time zone)"
-- -- "                                                        Rows Removed by Filter: 87596"
-- -- "Planning Time: 0.424 ms"
-- -- "Execution Time: 27.150 ms"

-- set enable_hashjoin = off;
-- set enable_mergejoin = on;
-- set enable_nestloop = off;

-- -- "GroupAggregate  (cost=14642.08..14653.94 rows=200 width=16) (actual time=52.465..53.492 rows=0 loops=1)"
-- -- "  Group Key: count_tickets.num_tickets"
-- -- "  ->  Sort  (cost=14642.08..14645.37 rows=1314 width=8) (actual time=52.463..53.490 rows=0 loops=1)"
-- -- "        Sort Key: count_tickets.num_tickets DESC"
-- -- "        Sort Method: quicksort  Memory: 25kB"
-- -- "        ->  Subquery Scan on count_tickets  (cost=6722.33..14574.02 rows=1314 width=8) (actual time=52.459..53.486 rows=0 loops=1)"
-- -- "              ->  Finalize GroupAggregate  (cost=6722.33..14560.88 rows=1314 width=15) (actual time=52.458..53.485 rows=0 loops=1)"
-- -- "                    Group Key: b.book_ref"
-- -- "                    ->  Gather Merge  (cost=6722.33..14540.10 rows=1528 width=15) (actual time=52.458..53.484 rows=0 loops=1)"
-- -- "                          Workers Planned: 2"
-- -- "                          Workers Launched: 2"
-- -- "                          ->  Partial GroupAggregate  (cost=5722.31..13363.71 rows=764 width=15) (actual time=48.908..48.909 rows=0 loops=3)"
-- -- "                                Group Key: b.book_ref"
-- -- "                                ->  Merge Join  (cost=5722.31..13352.25 rows=764 width=7) (actual time=48.907..48.908 rows=0 loops=3)"
-- -- "                                      Merge Cond: (t.book_ref = b.book_ref)"
-- -- "                                      ->  Parallel Index Only Scan using tickets_book_ref_idx on tickets t  (cost=0.42..7234.14 rows=152805 width=7) (actual time=0.083..0.083 rows=1 loops=3)"
-- -- "                                            Heap Fetches: 0"
-- -- "                                      ->  Sort  (cost=5721.88..5725.17 rows=1314 width=7) (actual time=48.823..48.823 rows=0 loops=3)"
-- -- "                                            Sort Key: b.book_ref"
-- -- "                                            Sort Method: quicksort  Memory: 25kB"
-- -- "                                            Worker 0:  Sort Method: quicksort  Memory: 25kB"
-- -- "                                            Worker 1:  Sort Method: quicksort  Memory: 25kB"
-- -- "                                            ->  Seq Scan on bookings b  (cost=0.00..5653.82 rows=1314 width=7) (actual time=48.809..48.810 rows=0 loops=3)"
-- -- "                                                  Filter: (date_trunc('mon'::text, book_date) = '2016-09-01 00:00:00+04'::timestamp with time zone)"
-- -- "                                                  Rows Removed by Filter: 262788"
-- -- "Planning Time: 0.364 ms"
-- -- "Execution Time: 53.535 ms"

-- set enable_hashjoin = off;
-- set enable_mergejoin = off;
-- set enable_nestloop = on;

-- -- "GroupAggregate  (cost=7539.05..7550.90 rows=200 width=16) (actual time=31.710..32.732 rows=0 loops=1)"
-- -- "  Group Key: count_tickets.num_tickets"
-- -- "  ->  Sort  (cost=7539.05..7542.33 rows=1314 width=8) (actual time=31.708..32.730 rows=0 loops=1)"
-- -- "        Sort Key: count_tickets.num_tickets DESC"
-- -- "        Sort Method: quicksort  Memory: 25kB"
-- -- "        ->  Subquery Scan on count_tickets  (cost=7299.04..7470.98 rows=1314 width=8) (actual time=31.703..32.725 rows=0 loops=1)"
-- -- "              ->  Finalize GroupAggregate  (cost=7299.04..7457.84 rows=1314 width=15) (actual time=31.702..32.723 rows=0 loops=1)"
-- -- "                    Group Key: b.book_ref"
-- -- "                    ->  Gather Merge  (cost=7299.04..7439.31 rows=1079 width=15) (actual time=31.701..32.722 rows=0 loops=1)"
-- -- "                          Workers Planned: 1"
-- -- "                          Workers Launched: 1"
-- -- "                          ->  Partial GroupAggregate  (cost=6299.03..6317.91 rows=1079 width=15) (actual time=28.366..28.367 rows=0 loops=2)"
-- -- "                                Group Key: b.book_ref"
-- -- "                                ->  Sort  (cost=6299.03..6301.73 rows=1079 width=7) (actual time=28.365..28.366 rows=0 loops=2)"
-- -- "                                      Sort Key: b.book_ref"
-- -- "                                      Sort Method: quicksort  Memory: 25kB"
-- -- "                                      Worker 0:  Sort Method: quicksort  Memory: 25kB"
-- -- "                                      ->  Nested Loop  (cost=0.42..6244.67 rows=1079 width=7) (actual time=28.339..28.340 rows=0 loops=2)"
-- -- "                                            ->  Parallel Seq Scan on bookings b  (cost=0.00..4030.72 rows=773 width=7) (actual time=28.338..28.338 rows=0 loops=2)"
-- -- "                                                  Filter: (date_trunc('mon'::text, book_date) = '2016-09-01 00:00:00+04'::timestamp with time zone)"
-- -- "                                                  Rows Removed by Filter: 131394"
-- -- "                                            ->  Index Only Scan using tickets_book_ref_idx on tickets t  (cost=0.42..2.84 rows=2 width=7) (never executed)"
-- -- "                                                  Index Cond: (book_ref = b.book_ref)"
-- -- "                                                  Heap Fetches: 0"
-- -- "Planning Time: 0.294 ms"
-- -- "Execution Time: 32.910 ms"

-- explain analyze 
-- select
-- 	num_tickets,
-- 	count(*) as num_bookings
-- from
-- 	(
-- 	select 
-- 		b.book_ref,
-- 		count(*)
-- 	from bookings b, tickets t
-- 	where date_trunc('mon', b.book_date) = '2016-09-01' and t.book_ref = b.book_ref
-- 	group by 1
-- 	) as count_tickets(book_ref, num_tickets)
-- group by num_tickets
-- order by num_tickets desc;

-- set enable_hashjoin = default;
-- set enable_mergejoin = default;
-- set enable_nestloop = default;


-- -- 14.
-- drop table if exists nulls;
-- create table nulls as
-- select num::integer, 'TEXT' || num::text as txt
-- from generate_series(1, 200_000) as gen_ser(num);

-- create index nulls_num_idx on nulls (num nulls last);

-- insert into nulls values (null, 'TEXT');

-- explain
-- select * from nulls order by num nulls last;
-- -- "Index Scan using nulls_num_idx on nulls  (cost=0.42..9556.42 rows=200000 width=36)"

-- explain
-- select * from nulls order by num desc nulls last;
-- -- "  ->  Seq Scan on nulls  (cost=0.00..3088.00 rows=200000 width=36)"


-- drop table if exists nulls;
-- create table nulls as
-- select num::integer, 'TEXT' || num::text as txt
-- from generate_series(1, 200_000) as gen_ser(num);

-- create index nulls_num_idx on nulls (num nulls first);

-- insert into nulls values (null, 'TEXT');

-- explain
-- select * from nulls order by num nulls first;
-- -- "Index Scan using nulls_num_idx on nulls  (cost=0.42..9556.42 rows=200000 width=36)"

-- explain
-- select * from nulls order by num desc nulls first;
-- -- -- "  ->  Seq Scan on nulls  (cost=0.00..3088.00 rows=200000 width=36)"


-- 16.
set enable_hashjoin = off;
set enable_mergejoin = off;
set enable_nestloop = off;

explain
select 
	a.model,
	count(*)
from aircrafts_data a, seats s
where
	a.aircraft_code = s.aircraft_code
group by a.aircraft_code;

-- "GroupAggregate  (cost=10000000000.41..10000000082.43 rows=9 width=76)" THE COSTS ARE LARGE
-- "  Group Key: a.aircraft_code"
-- "  ->  Nested Loop  (cost=10000000000.41..10000000075.65 rows=1339 width=68)" THE COSTS ARE LARGE
-- "        ->  Index Scan using aircrafts_pkey on aircrafts_data a  (cost=0.14..12.27 rows=9 width=68)"
-- "        ->  Index Only Scan using seats_pkey on seats s  (cost=0.28..5.55 rows=149 width=4)"
-- "              Index Cond: (aircraft_code = a.aircraft_code)"


explain analyze
select 
	a.model,
	count(*)
from aircrafts_data a, seats s
where
	a.aircraft_code = s.aircraft_code
group by a.aircraft_code;
-- "Planning Time: 0.127 ms"
-- "Execution Time: 1.855 ms"	