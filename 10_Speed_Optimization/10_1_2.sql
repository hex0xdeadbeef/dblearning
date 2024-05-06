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