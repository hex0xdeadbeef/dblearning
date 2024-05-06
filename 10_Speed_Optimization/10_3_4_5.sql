-- 10.2 Methods of the looking through the tables

explain select * from aircrafts_data;
-- "Seq Scan on aircrafts_data  (cost=0.00..1.09 rows=9 width=52)"
-- 0. Seq Scan is the method will be applied while looking through the table.
-- 1. cost=0.00..1.09 the the measurement of resources needed to perform the query
-- 2. 1.09 is the general cost of the query
-- 3. rows=9 the general number of the rows of the table
-- 4. width=52 is the average width in bytes while writing the rows out 
-- There will be "sequential scan"

explain (costs off) select * from aircrafts_data;
-- "Seq Scan on aircrafts_data"

explain select * from aircrafts where model like 'Боин%';
-- "Seq Scan on aircrafts_data ml  (cost=0.00..3.64 rows=1 width=52)"
-- "  Filter: ((model ->> lang()) ~~ 'Боин%'::text)"
-- Due to the fact we added the criteria of selection the number of the row got 1. The planner wrongly picked this number, we will have the 3 rows in fact.

explain select * from aircrafts_data order by model;
-- "Sort  (cost=1.23..1.26 rows=9 width=52)" is the top node of the panner's tree
-- "  Sort Key: model"
-- "  ->  Seq Scan on aircrafts_data  (cost=0.00..1.09 rows=9 width=52)" is the additional planner's tree node 
-- The number 1.23 reflects the cost of the time we need to wait until the output of the sorted rows. This number includes the sorting (1.23 - 1.09) and selection 
-- of the rows (1.09).


explain select * from bookings order by book_ref;
-- "Index Scan using bookings_pkey on bookings  (cost=0.42..8549.24 rows=262788 width=21)"
-- Index Scan using bookings_pkey is the looking method based on using the index.
-- The base cost of the query is not equal to 0.
-- After recognizing the needed key in the index, the referencing to the corresponding page (page size is the 8KB) and seizing the row found happens.

explain select * from bookings where book_ref > '0000FF' and book_ref < '000FFF' order by book_ref; 
-- "Index Scan using bookings_pkey on bookings  (cost=0.42..8.44 rows=1 width=21)"
-- "  Index Cond: ((book_ref > '0000FF'::bpchar) AND (book_ref < '000FFF'::bpchar))"
-- Due to the fact the table we filter with is indexed the collection of the rows is based on "Index Cond".


explain select * from seats where aircraft_code = 'SU9';
-- "Bitmap Heap Scan on seats  (cost=5.03..14.24 rows=97 width=15)" is the scanning of the seats based on bitmap
-- "  Recheck Cond: (aircraft_code = 'SU9'::bpchar)" 
-- "  ->  Bitmap Index Scan on seats_pkey  (cost=0.00..5.00 rows=97 width=0)" is the building the bitmap. The row width is 0 because the rows aren't selected on
-- this stage
-- "        Index Cond: (aircraft_code = 'SU9'::bpchar)" 
-- According to the previous example the selection is based on the index.


explain select book_ref from bookings where book_ref < '000FFF' order by book_ref;
-- "Index Only Scan using bookings_pkey on bookings  (cost=0.42..8.44 rows=1 width=7)" is the selection based only on index
-- "  Index Cond: (book_ref < '000FFF'::bpchar)"
-- The start cost if not 0 because the search of the lowes book_ref takes time.


explain select count(*) from seats where aircraft_code = 'SU9';
-- "Aggregate  (cost=6.22..6.23 rows=1 width=8)"
-- "  ->  Index Only Scan using seats_pkey on seats  (cost=0.28..5.97 rows=97 width=0)"
-- "        Index Cond: (aircraft_code = 'SU9'::bpchar)"

explain select avg(total_amount) from bookings;
-- "Finalize Aggregate  (cost=4644.38..4644.39 rows=1 width=32)"
-- "  ->  Gather  (cost=4644.27..4644.38 rows=1 width=32)"
-- "        Workers Planned: 1"
-- "        ->  Partial Aggregate  (cost=3644.27..3644.28 rows=1 width=32)"
-- "              ->  Parallel Seq Scan on bookings  (cost=0.00..3257.81 rows=154581 width=6)"


-- 10.3 Methods of Joining of rows sets

-- Nested Loops Method
explain
select
	a.aircraft_code,
	a.model -> 'en'::text,
	s.seat_no,
	s.fare_conditions
from seats s join aircrafts_data a on a.aircraft_code = s.aircraft_code
where a.model ->> 'en'::text like 'Air%'
order by s.seat_no;
-- "Sort  (cost=23.67..24.04 rows=149 width=59)"
-- "  Sort Key: s.seat_no"
-- "  ->  Nested Loop  (cost=5.43..18.29 rows=149 width=59)" is the method of joining rows
-- "        ->  Seq Scan on aircrafts_data a  (cost=0.00..1.14 rows=1 width=48)" is the method of looking through the rows of aircrafts_data
-- "              Filter: ((model ->> 'en'::text) ~~ 'Air%'::text)"
-- "        ->  Bitmap Heap Scan on seats s  (cost=5.43..15.29 rows=149 width=15)"
-- "              Recheck Cond: (aircraft_code = a.aircraft_code)"
-- "              ->  Bitmap Index Scan on seats_pkey  (cost=0.00..5.39 rows=149 width=0)" is the method of looking through the rows of seats
-- "                    Index Cond: (aircraft_code = a.aircraft_code)"

-- Joining with hashing
explain
select
	r.departure_airport_name,
	r.arrival_airport_name,
	a.model
from routes r join aircrafts_data a on r.aircraft_code = a.aircraft_code
order by r.flight_no;
-- "Sort  (cost=2870.85..2870.88 rows=12 width=103)"
-- "  Sort Key: flights.flight_no" is the key of sorting
-- "  ->  Hash Join  (cost=2447.75..2870.63 rows=12 width=103)"
-- "        Hash Cond: (flights.aircraft_code = a.aircraft_code)"
-- "        ->  Hash Join  (cost=2446.55..2865.93 rows=276 width=219)"
-- "              Hash Cond: (flights.arrival_airport = ml_1.airport_code)"
-- "              ->  Hash Join  (cost=2441.21..2719.78 rows=531 width=76)"
-- "                    Hash Cond: (flights.departure_airport = ml.airport_code)"
-- "                    ->  GroupAggregate  (cost=2435.87..2701.49 rows=1022 width=67)"
-- "                          Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure))"
-- "                          ->  Sort  (cost=2435.87..2461.41 rows=10216 width=39)"
-- "                                Sort Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure)), ((to_char(flights.scheduled_departure, 'ID'::text))::integer)"
-- "                                ->  HashAggregate  (cost=1551.24..1755.56 rows=10216 width=39)"
-- "                                      Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, (flights.scheduled_arrival - flights.scheduled_departure), (to_char(flights.scheduled_departure, 'ID'::text))::integer"
-- "                                      ->  Seq Scan on flights  (cost=0.00..1054.42 rows=33121 width=39)"
-- "                    ->  Hash  (cost=4.04..4.04 rows=104 width=65)"
-- "                          ->  Seq Scan on airports_data ml  (cost=0.00..4.04 rows=104 width=65)"
-- "              ->  Hash  (cost=4.04..4.04 rows=104 width=65)"
-- "                    ->  Seq Scan on airports_data ml_1  (cost=0.00..4.04 rows=104 width=65)"
-- "        ->  Hash  (cost=1.09..1.09 rows=9 width=48)"
-- "              ->  Seq Scan on aircrafts_data a  (cost=0.00..1.09 rows=9 width=48)" 

-- Joining with merging
explain select
	t.ticket_no,
	t.passenger_name,
	tf.flight_id,
	tf.amount
from tickets t join ticket_flights tf on t.ticket_no = tf.ticket_no
order by t.ticket_no;
-- "Merge Join  (cost=0.85..102825.90 rows=1045726 width=40)" is the method of rows joining
-- "  Merge Cond: (t.ticket_no = tf.ticket_no)"
-- "  ->  Index Scan using tickets_pkey on tickets t  (cost=0.42..17340.42 rows=366733 width=30)"
-- "  ->  Index Scan using ticket_flights_pkey on ticket_flights tf  (cost=0.42..71497.08 rows=1045726 width=24)"


-- 10.4 Planner forcing
-- As default these parameters is ON. After the turning off these parameters the method will have the high cost of execution, but the planner will have tiny 
-- opportunity to use it.

-- Forcing planner not to use hashing method while joining:
set enable_hashjoin = off;

-- Forcing planner not to use merging method while joining:
set enable_mergejoin = off;

-- Forcing planner not to use nested loop method while joining:
set enable_nestloop = off;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
set enable_hashjoin = default;
set enable_mergejoin = default;
set enable_nestloop = default;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

set enable_mergejoin = off;
explain
select
	t.ticket_no,
	t.passenger_name,
	tf.flight_id,
	tf.amount
from tickets t join ticket_flights tf on t.ticket_no = tf.ticket_no
order by t.ticket_no;
-- "Gather Merge  (cost=84818.31..186493.17 rows=871438 width=40)" -- THE COST OF THE QUERY GOT HIGHER VALUES
-- "  Workers Planned: 2"
-- "  ->  Sort  (cost=83818.29..84907.58 rows=435719 width=40)"
-- "        Sort Key: t.ticket_no"
-- "        ->  Parallel Hash Join  (cost=10659.12..31089.08 rows=435719 width=40)" -- THE NEW METHOD OF JOINING
-- "              Hash Cond: (tf.ticket_no = t.ticket_no)"
-- "              ->  Parallel Seq Scan on ticket_flights tf  (cost=0.00..13133.19 rows=435719 width=24)"
-- "              ->  Parallel Hash  (cost=7704.05..7704.05 rows=152805 width=30)"
-- "                    ->  Parallel Seq Scan on tickets t  (cost=0.00..7704.05 rows=152805 width=30)"

-- There's the option for the EXPLAIN that's called ANALYZE. It allows to output the actual time and rows processed, but the rows won't be written out.
set enable_mergejoin = default;
explain analyze
select
	t.ticket_no,
	t.passenger_name,
	tf.flight_id,
	tf.amount
from tickets t join ticket_flights tf on t.ticket_no = tf.ticket_no
order by t.ticket_no;
-- "Merge Join  (cost=0.85..102825.90 rows=1045726 width=40) (actual time=0.614..1150.689 rows=1045726 loops=1)" "loops" IS THE COUNTER OF REPETITIONS OF
-- PROCESSING OF NODES
-- "  Merge Cond: (t.ticket_no = tf.ticket_no)"
-- "  ->  Index Scan using tickets_pkey on tickets t  (cost=0.42..17340.42 rows=366733 width=30) (actual time=0.336..41.059 rows=366733 loops=1)"
-- "  ->  Index Scan using ticket_flights_pkey on ticket_flights tf  (cost=0.42..71497.08 rows=1045726 width=24) (actual time=0.270..717.516 rows=1045726 loops=1)"
-- "Planning Time: 0.432 ms" -- THE TIME COST OF PLANNING THE QUERY
-- "Execution Time: 1168.465 ms" -- THE TIME COST OF EXECUTION OF QUERY

set enable_mergejoin = default;
explain analyze
select
	t.ticket_no,
	t.passenger_name,
	tf.flight_id,
	tf.amount
from tickets t join ticket_flights tf on t.ticket_no = tf.ticket_no
where amount > 50_000
order by t.ticket_no;
-- "Gather Merge  (cost=26347.27..33624.75 rows=62374 width=40) (actual time=120.180..175.271 rows=72647 loops=1)" -- THE COUNTS OF ROWS MISMATCH
-- "  Workers Planned: 2"
-- "  Workers Launched: 2"
-- "  ->  Sort  (cost=25347.25..25425.22 rows=31187 width=40) (actual time=111.348..111.831 rows=24216 loops=3)"
-- "        Sort Key: t.ticket_no"
-- "        Sort Method: quicksort  Memory: 2433kB" -- IS THE OUTER SORT IN DISK SPACE
-- "        Worker 0:  Sort Method: quicksort  Memory: 2385kB"
-- "        Worker 1:  Sort Method: quicksort  Memory: 2471kB"
-- "        ->  Parallel Hash Join  (cost=14612.33..23019.35 rows=31187 width=40) (actual time=25.641..47.166 rows=24216 loops=3)"
-- "              Hash Cond: (t.ticket_no = tf.ticket_no)"
-- "              ->  Parallel Seq Scan on tickets t  (cost=0.00..7704.05 rows=152805 width=30) (actual time=0.026..7.303 rows=122244 loops=3)"
-- "              ->  Parallel Hash  (cost=14222.49..14222.49 rows=31187 width=24) (actual time=25.319..25.319 rows=24216 loops=3)"
-- "                    Buckets: 131072  Batches: 1  Memory Usage: 5600kB"
-- "                    ->  Parallel Seq Scan on ticket_flights tf  (cost=0.00..14222.49 rows=31187 width=24) (actual time=0.021..22.430 rows=24216 loops=3)"
-- "                          Filter: (amount > '50000'::numeric)"
-- "                          Rows Removed by Filter: 324360" -- THE NUMBER OF ROWS THAT WERE DELETED WHILE FILTERING
-- "Planning Time: 0.208 ms"
-- "Execution Time: 176.514 ms"

explain (analyze, costs off)
select
	a.aircraft_code,
	a.model,
	s.seat_no,
	s.fare_conditions
from seats s join aircrafts_data a on s.aircraft_code = a.aircraft_code
where a.model ->> 'en' ilike 'air%'
order by s.seat_no;
-- "Sort (actual time=0.910..0.918 rows=426 loops=1)"
-- "  Sort Key: s.seat_no"
-- "  Sort Method: quicksort  Memory: 68kB" -- THE METHOD OF SORT IN DISK SPACE
-- "  ->  Nested Loop (actual time=0.040..0.092 rows=426 loops=1)"
-- "        ->  Seq Scan on aircrafts_data a (actual time=0.010..0.013 rows=3 loops=1)"
-- "              Filter: ((model ->> 'en'::text) ~~* 'air%'::text)"
-- "              Rows Removed by Filter: 6" -- THE NUMBER OF ROWS THAT WERE REMOVED WHILE FILTERING
-- "        ->  Bitmap Heap Scan on seats s (actual time=0.015..0.020 rows=142 loops=3)" -- THE NUMBER OF USING THE NODE
-- "              Recheck Cond: (aircraft_code = a.aircraft_code)"
-- "              Heap Blocks: exact=6"
-- "              ->  Bitmap Index Scan on seats_pkey (actual time=0.012..0.012 rows=142 loops=3)"
-- "                    Index Cond: (aircraft_code = a.aircraft_code)"
-- "Planning Time: 0.075 ms"
-- "Execution Time: 0.935 ms"

-- Using ANALYZE on UPDATE operation

-- TERMINAL 2
-- begin;
-- BEGIN
explain (analyze, costs off)
update aircrafts_data
set range = range + 100
where model ->> 'en' ilike 'air%';
-- "Update on aircrafts_data (actual time=0.086..0.086 rows=0 loops=1)"
-- "  ->  Seq Scan on aircrafts_data (actual time=0.015..0.018 rows=3 loops=1)"
-- "        Filter: ((model ->> 'en'::text) ~~* 'air%'::text)"
-- "        Rows Removed by Filter: 6"
-- "Planning Time: 0.050 ms"
-- "Execution Time: 0.202 ms"
-- rollback;


-- 10.5 Queries optimization

-- Updating statistics
analyze aircrafts_data;

explain
select
	num_tickets, 
	count (*) as num_bookings
from (
	select 
		b.book_ref,
		(select count(*) from tickets t where t.book_ref = b.book_ref)
	from bookings b
	where date_trunc('month', book_date) = '2016-09-01'
) as count_tickets(book_ref, num_tickets)
group by num_tickets
order by num_tickets desc;
-- "GroupAggregate  (cost=14144103.42..28282999.65 rows=1314 width=16)"
-- "  Group Key: ((SubPlan 1))"
-- "  ->  Sort  (cost=14144103.42..14144106.70 rows=1314 width=8)"
-- "        Sort Key: ((SubPlan 1)) DESC"
-- "        ->  Gather  (cost=1000.00..14144035.35 rows=1314 width=8)"
-- "              Workers Planned: 1"
-- "              ->  Parallel Seq Scan on bookings b  (cost=0.00..4030.72 rows=773 width=7)"
-- "                    Filter: (date_trunc('month'::text, book_date) = '2016-09-01 00:00:00+04'::timestamp with time zone)"
-- "              SubPlan 1"
-- "                ->  Aggregate  (cost=10760.17..10760.18 rows=1 width=8)"
-- "                      ->  Seq Scan on tickets t  (cost=0.00..10760.16 rows=2 width=0)"
-- "                            Filter: (book_ref = b.book_ref)"

drop index if exists tickets_book_ref_idx;
create index tickets_book_ref_idx on tickets (book_ref);
explain (analyze)
select
	num_tickets, 
	count (*) as num_bookings
from (
	select 
		b.book_ref,
		(select count(*) from tickets t where t.book_ref = b.book_ref)
	from bookings b
	where date_trunc('month', book_date) = '2016-09-01'
) as count_tickets(book_ref, num_tickets)
group by num_tickets
order by num_tickets desc;
-- "GroupAggregate  (cost=16363.05..27518.91 rows=1314 width=16) (actual time=20.922..21.624 rows=0 loops=1)"
-- "  Group Key: ((SubPlan 1))"
-- "  ->  Sort  (cost=16363.05..16366.33 rows=1314 width=8) (actual time=20.921..21.623 rows=0 loops=1)"
-- "        Sort Key: ((SubPlan 1)) DESC"
-- "        Sort Method: quicksort  Memory: 25kB"
-- "        ->  Gather  (cost=1000.00..16294.98 rows=1314 width=8) (actual time=20.913..21.615 rows=0 loops=1)"
-- "              Workers Planned: 1"
-- "              Workers Launched: 1"
-- "              ->  Parallel Seq Scan on bookings b  (cost=0.00..4030.72 rows=773 width=7) (actual time=19.918..19.918 rows=0 loops=2)"
-- "                    Filter: (date_trunc('month'::text, book_date) = '2016-09-01 00:00:00+04'::timestamp with time zone)"
-- "                    Rows Removed by Filter: 131394"
-- "              SubPlan 1"
-- "                ->  Aggregate  (cost=8.46..8.47 rows=1 width=8) (never executed)"
-- "                      ->  Index Only Scan using tickets_book_ref_idx on tickets t  (cost=0.42..8.46 rows=2 width=0) (never executed)"
-- "                            Index Cond: (book_ref = b.book_ref)"
-- "                            Heap Fetches: 0"
-- "Planning Time: 0.114 ms"
-- "Execution Time: 21.641 ms"


explain (analyze)
select	
	num_tickets,
	count(*) as num_bookings
from (
	select 
		b.book_ref,
		count(*)
		from bookings b, tickets t
		where 
			date_trunc('mon', b.book_date) = '2016-09-01' and t.book_ref = b.book_ref
		group by b.book_ref
	) as count_tickets(book_ref, num_tickets)
group by num_tickets
order by num_tickets desc;
-- "GroupAggregate  (cost=7539.05..7550.90 rows=200 width=16) (actual time=14.040..14.772 rows=0 loops=1)"
-- "  Group Key: count_tickets.num_tickets"
-- "  ->  Sort  (cost=7539.05..7542.33 rows=1314 width=8) (actual time=14.040..14.772 rows=0 loops=1)"
-- "        Sort Key: count_tickets.num_tickets DESC"
-- "        Sort Method: quicksort  Memory: 25kB"
-- "        ->  Subquery Scan on count_tickets  (cost=7299.04..7470.98 rows=1314 width=8) (actual time=14.036..14.768 rows=0 loops=1)"
-- "              ->  Finalize GroupAggregate  (cost=7299.04..7457.84 rows=1314 width=15) (actual time=14.036..14.768 rows=0 loops=1)"
-- "                    Group Key: b.book_ref"
-- "                    ->  Gather Merge  (cost=7299.04..7439.31 rows=1079 width=15) (actual time=14.036..14.768 rows=0 loops=1)"
-- "                          Workers Planned: 1"
-- "                          Workers Launched: 1"
-- "                          ->  Partial GroupAggregate  (cost=6299.03..6317.91 rows=1079 width=15) (actual time=12.787..12.787 rows=0 loops=2)"
-- "                                Group Key: b.book_ref"
-- "                                ->  Sort  (cost=6299.03..6301.73 rows=1079 width=7) (actual time=12.786..12.787 rows=0 loops=2)"
-- "                                      Sort Key: b.book_ref"
-- "                                      Sort Method: quicksort  Memory: 25kB"
-- "                                      Worker 0:  Sort Method: quicksort  Memory: 25kB"
-- "                                      ->  Nested Loop  (cost=0.42..6244.67 rows=1079 width=7) (actual time=12.776..12.776 rows=0 loops=2)"
-- "                                            ->  Parallel Seq Scan on bookings b  (cost=0.00..4030.72 rows=773 width=7) (actual time=12.776..12.776 rows=0 loops=2)"
-- "                                                  Filter: (date_trunc('mon'::text, book_date) = '2016-09-01 00:00:00+04'::timestamp with time zone)"
-- "                                                  Rows Removed by Filter: 131394"
-- "                                            ->  Index Only Scan using tickets_book_ref_idx on tickets t  (cost=0.42..2.84 rows=2 width=7) (never executed)"
-- "                                                  Index Cond: (book_ref = b.book_ref)"
-- "                                                  Heap Fetches: 0"
-- "Planning Time: 0.206 ms"
-- "Execution Time: 14.793 ms"