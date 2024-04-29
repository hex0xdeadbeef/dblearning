-- -- 6.1 Additional opportunities of SELECT operator
-- select * from aircrafts where model like 'Аэробус%'; -- Find prefix 
-- select * from aircrafts where model like '%200'; -- Find postfix
-- select * from aircrafts where model like '%с%'; -- find substring

-- select * from aircrafts where model not like 'Аэробус%' and model not like 'Боинг%'; -- negotiation of like operator, we'll be finding the aircrafts except 'Boeing'
-- -- and 'Airbus'.

-- select * from airports where airport_name like '___'; -- the character '_' corresponds to a random symbol.
-- select * from aircrafts where model ~'^(А|Бои)'; -- the '~' operator finds all the mathces with register sensitivity.
-- -- As for "^", this one is responsible for binding the search to the start of the string. On the other hand, if we want to check whether the symbol is present in
-- -- a row in general, we should use '\'.
-- -- The "|" means "or"
-- select * from aircrafts where model !~'300$';
-- -- The "!~" is inverted "~"
-- -- The "$" is the binding the search to the ending of the string

-- select * from aircrafts where range between 3000 and 6000;
-- -- the "betweeen" operator is the comparing predicate. The right boundary is included while using "between";

-- select model, range, range / 1.609 as miles from aircrafts;
-- select model, range, round(range/1.609, 2) as miles from aircrafts;
-- -- round is used to round the accuracy of float/real/double precision/numeric types while calculating.

-- select * from aircrafts order by range desc;

-- select timezone from airports;
-- select distinct timezone from airports order by 1;
-- -- "distinct" is used to output only the unique values presented in a table
-- -- in "order by 1" the "1" means the 1st column in the select statement 

-- select * from airports order by timezone desc limit 3;
-- -- "limit N" is used to truncate the output to N rows of a table
-- select * from airports order by timezone desc limit 3 offset 3;
-- -- "offset N" is used to skip first N elements from the start of the selected rows

-- select model,
-- 	range,
-- 	case when range < 2000 then 'A'
-- 		when range < 5000 then 'B'
-- 		else 'C'
-- 		end as type
-- from aircrafts
-- order by model;


-- -- 6.2 Joins
-- -- select * from aircrafts join seats;

-- select a.aircraft_code, a.model, s.seat_no, s.fare_conditions from aircrafts as a join seats as s on a.aircraft_code = s.aircraft_code
-- 	where a.model like 'Сес%'
-- 	order by seat_no;

-- select s.seat_no, s.fare_conditions from seats s join aircrafts a on s.aircraft_code = a.aircraft_code
-- 	where model like 'Сес%'
-- 	order by s.seat_no;

-- select a.aircraft_code, a.model, s.seat_no, s.fare_conditions from aircrafts as a, seats as s
-- 	where a.aircraft_code = s.aircraft_code and a.model like 'Сес%'
-- 	order by s.seat_no;

-- drop view if exists flights_v ;
-- create or replace view flights_v as select 
-- 	f.flight_id, flight_no, f.scheduled_departure, timezone(dep.timezone, f.scheduled_departure) as scheduled_departure_local,
-- 	f.scheduled_arrival, timezone(arr.timezone, f.scheduled_arrival) as scheduled_arrival_local, f.scheduled_arrival - f.scheduled_departure as scheduled_duration,
-- 	f.departure_airport, dep.airport_name as departure_airport_name, dep.city as departure_city, f.arrival_airport, arr.airport_name as arrival_airport_name, 
-- 	arr.city as arrival_city, f.status, f.aircraft_code, f.actual_departure, timezone(arr.timezone, f.actual_departure) as actual_arrival_local,
-- 	f.actual_arrival - f.actual_departure as actual_duration from flights as f, airports as dep, airports as arr where f.departure_airport = dep.airport_code and
-- 	f.arrival_airport = arr.airport_code;

-- select * from flights_v;

-- select count(*) from airports as a1, airports as a2 where a1.city <> a2.city;
-- select count(*) from airports as a1 join airports as a2 on a1.city <> a2.city;
-- select count(*) from airports as a1 cross join airports as a2 where a1.city <> a2.city;
-- -- cross join makes the cartesian's product explicitly without considering the condition

-- select a.aircraft_code, a.model, count(*) from routes r, aircrafts a where a.aircraft_code = r.aircraft_code group by a.aircraft_code, a.model order by count(*) desc;
-- select a.aircraft_code, a.model, count(*) from aircrafts as a join routes as r on a.aircraft_code = r.aircraft_code group by a.aircraft_code, a.model order by count(*) desc ;
-- -- select count(*) from (select a.aircraft_code, a.model, count(*) from aircrafts as a join routes as r on a.aircraft_code = r.aircraft_code group by a.aircraft_code, a.model); -- 8
-- -- select count(*) from aircrafts; -- 9

-- select a.aircraft_code, a.model, r.aircraft_code, count(r.aircraft_code) from aircrafts a left join routes r on a.aircraft_code = r.aircraft_code
-- 	group by 1,2,3
-- 	order by 4 desc;
-- -- ... left join ... on "condition" is used to search the coresspondances between left side table and right side table. If there are no correspondances for the
-- -- left side row, the right side attr will have the null value.

-- select r.aircraft_code, a.model, a.aircraft_code, count(r.aircraft_code) from aircrafts a right join routes r on a.aircraft_code = r.aircraft_code
-- 	group by 1,2,3
-- 	order by 4 desc;
-- -- -||- for the right side

-- select count(*) from (ticket_flights as t join flights as f on t.flight_id = f.flight_id) left join boarding_passes as b on t.ticket_no = b.ticket_no
-- 	and t.flight_id = b.flight_id where f.actual_departure is not null and b.flight_id is null;

-- update boarding_passes set seat_no = '1A' where flight_id = 1 and seat_no = '17A';
-- select f.flight_no,
-- 		f.scheduled_departure,
-- 		f.flight_id,
-- 		f.departure_airport,
-- 		f.arrival_airport,
-- 		f.aircraft_code,
-- 		t.passenger_name,
-- 		tf.fare_conditions as fc_to_be,
-- 		s.fare_conditions as fc_fact,
-- 		b.seat_no
-- from boarding_passes as b
-- join ticket_flights as tf
-- on b.ticket_no = tf.ticket_no and b.flight_id = tf.flight_id
-- join tickets as t on tf.ticket_no = t.ticket_no
-- join flights as f on tf.flight_id = f.flight_id
-- join seats as s on b.seat_no = s.seat_no and f.aircraft_code = s.aircraft_code
-- where tf.fare_conditions <> s.fare_conditions 
-- order by f.flight_no, f.scheduled_departure;

-- select r.min_sum, r.max_sum, count(b.*) from (values (0, 100000), (100000, 200000), (200000, 300000), (300000, 400000), (400000, 500000), (500000, 600000), (600000, 700000), (700000, 800000),
-- 	(800000, 900000),(900000, 1000000), (1000000, 1100000), (1100000, 1200000), (1200000, 1300000)) as r (min_sum, max_sum) left join bookings as b
-- 	on b.total_amount >= r.min_sum and b.total_amount < r.max_sum group by r.min_sum, r.max_sum order by r.min_sum;


-- select arrival_city from routes where departure_city = 'Москва' union select arrival_city from routes where departure_city = 'Санкт-Петербург';
-- select arrival_city from routes where departure_city = 'Москва' union all select arrival_city from routes where departure_city = 'Санкт-Петербург';
-- -- The "union" is the operation that means the unioning of two tables.
-- -- The conditions for the "union" op to be used:
-- 	-- The number of columns are equal
-- 	-- The types of columns are equal
-- -- "union all" is used to leave the duplicates of rows matched

-- select arrival_city from routes where departure_city = 'Москва' intersect select arrival_city from routes where departure_city = 'Санкт-Петербург';
-- -- The "intersect" is the operation that means the intersection of two tables.
-- -- The conditions for the "intersect" op to be used:
-- 	-- The number of columns are equal
-- 	-- The types of columns are equal
-- -- "intersect all" is used to leave the duplicates of rows matched

-- select arrival_city from routes where departure_city = 'Санкт-Петербург' except select arrival_city from routes where departure_city = 'Москва';
-- -- The "intersect" is the operation that means the subtraction of two tables.
-- -- The conditions for the "intersection" op to be used:
-- 	-- The number of columns is equal
-- 	-- The types of columns are equal
-- -- "except all" is used to leave the duplicates of rows matched


-- -- 6.3 Agregation and Grouping
-- select avg(total_amount) from bookings; -- 79025.605811528685
-- select max(total_amount) from bookings; -- 1204500.00
-- select min(total_amount) from bookings; -- 3400.00

-- select arrival_city, count(*) from routes where departure_city = 'Москва' group by arrival_city order by count desc;
-- select array_length(days_of_week, 1) as days_of_week, count(*) from routes group by 1 order by 2 desc;

-- select departure_city, count(*) from routes group by departure_city having count(*) >= 15 order by count desc;
-- select city, count(*) from airports group by city having count(*) > 1;


-- 6.4 Subqueries
-- select count(*) from bookings where total_amount > (select avg(total_amount) from bookings);
-- -- This is a scalar subquery
-- -- The second select is the subquery
-- -- Subqueries can include: select, from, where, group by, having and with.

-- select * from routes 
-- 	where
-- 	departure_city in (select city from airports where timezone like '%Krasnoyarsk')
-- 	and
-- 	arrival_city in (select city from airports where timezone like '%Krasnoyarsk');
-- -- This query is not correlative because the subquery doesn't refer to the outer select attrs

-- select airport_name, city, coordinates[0] from airports
-- 	where coordinates[0] in
-- 	((select min(coordinates[0]) from airports), (select max(coordinates[0]) from airports))
-- 	order by coordinates[0];
-- -- This subquery uses "in" predicate so that the result includes only appropriate rows

-- select airport_name, city, coordinates[0] from airports
-- 	where coordinates[0] not in
-- 	((select min(coordinates[0]) from airports), (select max(coordinates[0]) from airports))
-- 	order by coordinates[0];
-- -- This subquery uses "in" predicate so that the result includes only inappropriate rows


-- select distinct a.city from airports as a
-- 	where not exists (select 1 from routes as r where r.departure_city like 'Москва' and r.arrival_city = a.city) and a.city not like 'Москва'
-- 	order by city;
-- -- This is correlative query. It means that the subquery is calculated for every row from the airpots. The subquery is calculated for every row of the outer
-- -- table.
-- -- "exists" or "not exists" is used to find out whether or not the appropriate row is present in the outer table.

-- select a.model,
-- 	(select count(*) from seats as s where a.aircraft_code = s.aircraft_code and s.fare_conditions like 'Business'),
-- 	(select count(*) from seats as s where a.aircraft_code = s.aircraft_code and s.fare_conditions like 'Comfort'),
-- 	(select count(*) from seats as s where a.aircraft_code = s.aircraft_code and s.fare_conditions like 'Economy') from aircrafts as a
-- order by 1;
-- -- This query is the correlative query where the subqueries is calculated for every row of the airports table.


-- select s2.model,
-- 	string_agg(s2.fare_conditions || ' (' || s2.num || ')',  ', ')
-- from (select a.model, s.fare_conditions, count(*) as num from aircrafts a join seats as s on a.aircraft_code = s.aircraft_code group by 1, 2 order by 1,2) as s2
-- group by s2.model
-- order by s2.model;

-- select aa.city, aa.airport_code, aa.airport_name
-- from (select city, count(*) from airports group by city having count(*) > 1) as a
-- join airports as aa on a.city like aa.city
-- order by aa.city, aa.airport_name;
-- -- This is subquery that is used in "from"

-- select departure_airport, departure_city, count(*) from routes
-- 	group by departure_airport, departure_city
-- 	having departure_airport in (select airport_code from airports where coordinates[0] > 150)
-- order by count desc;
-- -- This is subquery that is used in "having" filter

-- select ts.flight_id, ts.flight_no, ts.scheduled_departure_local, ts.departure_city, ts.arrival_city, a.model, ts.fact_passengers, ts.total_seats,
-- 		round(ts.fact_passengers::numeric/ts.total_seats::numeric, 2) as fraction 
-- from (
-- 	select f.flight_id, f.flight_no, f.scheduled_departure_local, f.departure_city, f.arrival_city, f.aircraft_code, count(tf.ticket_no) as fact_passengers,
-- 			(select count(s.seat_no) from seats as s where s.aircraft_code = f.aircraft_code) as total_seats from flights_v as f
-- join ticket_flights as tf on f.flight_id = tf.flight_id where f.status like 'Arrived' group by 1,2,3,4,5,6) as ts
-- join aircrafts as a on ts.aircraft_code = a.aircraft_code
-- order by ts.scheduled_departure_local, fraction desc;
-- -- This is the subquery that includes another one subquery in itself

-- with ts as (
-- 	select f.flight_id, f.flight_no, f.scheduled_departure_local, f.departure_city, f.arrival_city, f.aircraft_code, count(tf.ticket_no) as fact_passengers,
-- 			(select count(s.seat_no) from seats as s where s.aircraft_code = f.aircraft_code) as total_seats from flights_v as f
-- join ticket_flights as tf on f.flight_id = tf.flight_id where f.status like 'Arrived' group by 1,2,3,4,5,6)
-- -- The construction "with cte_name as (...)" is "Commnon Table Expression". All the subqueries in CTE forms a temporary table with the specified "cte_name" in
-- -- advance in the declaration of the CTE. The temporary table in the CTE is alive only within the transaction.
-- select ts.flight_id, ts.flight_no, ts.scheduled_departure_local, ts.departure_city, ts.arrival_city, a.model, ts.fact_passengers, ts.total_seats,
-- 		round(ts.fact_passengers::numeric/ts.total_seats::numeric, 2) as fraction from ts join aircrafts as a on ts.aircraft_code = a.aircraft_code
-- order by ts.scheduled_departure_local;

with recursive ranges (min_sum, max_sum) as (
	values(0, 100_000)
	union all
	select min_sum + 100_000, max_sum + 100_000 from ranges
	where max_sum < (select max(total_amount) from bookings)
)
-- "with recursive recursive_cte_name as (...)" is the recursive CTE. We must constrain the edge case of the recursion so that it ends finally. It's also the 
-- temporary talbe that is generated based on the conditions and start values.
-- The algorithm:
	-- 1. At the beginning the sentence "values(0, 100_000)" is perfomed and the result is written into the temporary memory area. It's the base of the recursion.
	-- 2. After the 1. the query is applied to the base "select min_sum + 100_000, max_sum + 100_000 from ranges".
	-- 3. The new formed row is combined with the previous results with the "union [all]" command.
	-- The 2. and 3. is repeated before the edge case "where max_sum < (select max(total_amount) from bookings)" is met.
-- The query is the scalar. We refer to the one row and one column of the table bookings
select r.min_sum, r.max_sum, count(b.*) from bookings as b right join ranges as r on b.total_amount >= r.min_sum and b.total_amount < r.max_sum
group by 1,2
order by 1;