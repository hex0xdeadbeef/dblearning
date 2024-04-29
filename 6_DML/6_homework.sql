-- 1.
-- select count(*) from tickets; -- 366733
-- select count(*) from tickets where passenger_name like '% %'; -- 366733
-- -- The '%' considers the space as an ordinary symbol;
-- select count(*) from tickets where passenger_name like '% % %'; -- 0
-- select count(*) from tickets where passenger_name like '% %%'; -- 366733


-- 2.
-- select passenger_name from tickets where passenger_name like '___ %';
-- -- This query gathers only the rows where the name is represented as a three-symbols sequence;
-- select passenger_name from tickets where passenger_name like '_____ %';
-- -- This query gathers only the rows where the name is represented as a five-symbols sequence;


-- 3.


-- 4.
-- There are the following predicates:
	-- a BETWEEN x AND y where y is included
	-- a NOT BETWEEN x AND y

	-- Ordinary comparison operators yield "null", not true or false, when either input is null, 7 = NULL yields "null", as does 7 <> NULL. When this behavior is
	-- not suitable we should use "IS [NOT]" DISTINCT FROM. For example:
	-- a IS DISCTINCT FROM b
	-- a IS NOT DISTINCT FROM b

	-- To check whether or not the expression is NULL whe should use the predicate "IS [NOT] NULL". For example:
	-- expression IS NULL
	-- expression IS NOT NULL

	-- Boolean values can be tested using the constructs:
	-- expression IS TRUE
	-- expression NOT TRUE
	-- expression IS FALSE
	-- expression NOT FALSE
	-- expression IS UNKNOWN
	-- expression IS NOT UNKNOWN

-- 5. 
-- COALESCE(arg1, ..., argN) function returns the first of its arguments that is not null. NULL is returned only if all the arguments are NULL. Arguments to the
-- right of the first non-null argument are not evaluated.

-- NULLIF(value1, value2) returns a null value if value1 is equal to value2; otherwise it returns value1.

-- GREATEST(value, [...]) or LEAST(value, [...]) select the largest or the smallest value from a list of any number of expressions. The expressions must all be
-- convertible to a common data type, which will be the type of the result. NULL values in the list are ignored. The result will be NULL if all the expressions
-- evaluate to NULL.


-- 6.
-- select * from routes;
-- select * from routes as r, aircrafts as a where a.model like 'Боинг%' and a.aircraft_code = r.aircraft_code order by a.model;
-- select * from routes as r join aircrafts as a on a.model like 'Боинг%' and a.aircraft_code = r.aircraft_code and r.days_of_week @> '{2, 4, 6}'::integer[];


-- 7.
-- select distinct least(departure_city, arrival_city) as departure_city , greatest(departure_city, arrival_city) as arrival_city
-- from routes as r
-- join aircrafts as a on r.aircraft_code = a.aircraft_code
-- where a.model like '%777-300'
-- order by 1;


-- 8.
-- select a.aircraft_code, a.model, a.range, count(r.*) from aircrafts as a full outer join routes as r on a.aircraft_code = r.aircraft_code
-- 	group by 1,2,3
-- 	order by 4;


-- 9.
-- select departure_city, arrival_city, count(*) from routes where departure_city like 'Москва' and arrival_city like 'Санкт-Петербург' group by 1,2;


-- 10.
-- select arrival_city, count(*) from (select departure_city, arrival_city, count(*) from routes as r group by 1,2) group by arrival_city order by count desc;


-- 11.
-- select r.arrival_city, days_of_week, count(arrival_city) from routes as r where departure_city = 'Москва' and array_length(days_of_week, 1) = 7  group by 1,2 order by count desc limit 5;


-- 12.
-- select unnest(days_of_week) as day_of_week , count(*) as num_flights from routes where departure_city like 'Москва' group by day_of_week order by num_flights;

-- select dw.name_of_day, count(*) as num_flights
-- from (
-- 	select unnest(days_of_week) as num_of_day
-- 	from routes
-- 	where departure_city like 'Москва'
-- ) as r,
-- unnest ('{1,2,3,4,5,6,7}'::integer[], '{"Mon.", "Tue.", "Wen.", "Thu.", "Fri.", "Sat.", "Sun"}'::text[]) as dw(num_of_day, name_of_day)
-- where r.num_of_day = dw.num_of_day
-- group by r.num_of_day, dw.name_of_day
-- order by r.num_of_day;

-- select dw.name_of_day, count(*) as num_flights
-- from (
-- 	select unnest(days_of_week) as num_of_day
-- 	from routes
-- 	where departure_city like 'Москва'
-- ) as r,
-- unnest ('{"Mon.", "Tue.", "Wen.", "Thu.", "Fri.", "Sat.", "Sun"}'::text[]) with ordinality as dw(name_of_day, num_of_day)
-- where r.num_of_day = dw.num_of_day
-- group by r.num_of_day, dw.name_of_day
-- order by r.num_of_day;


-- 13.
-- select f.departure_city, f.arrival_city, max(tf.amount), min(tf.amount)
-- from flights_v as f
-- left join ticket_flights as tf on f.flight_id = tf.flight_id
-- group by 1,2
-- order by 1,2;


-- 14.
-- select right(passenger_name, length(passenger_name) - strpos(passenger_name, ' ')) as firstname, count(*)
-- from tickets
-- group by 1
-- order by 2 desc;

-- 15. 
-- select * from aircrafts;
-- select a.model, avg(a.range) over () from aircrafts as a order by a.model
-- select a.model, avg(a.range) over (partition by left(a.model, strpos(a.model, ' ') - 1)) from aircrafts as a order by avg;
-- select a.model, avg(a.range) over (partition by left(a.model, strpos(a.model, ' ') - 1) order by a.model) from aircrafts as a order by avg;
-- select a.model, rank() over (partition by left(a.model, strpos(a.model, ' ') - 1) order by a.model) from aircrafts as a order by rank;

-- select * from aircrafts order by range;
-- "CN1"	"Сессна 208 Караван"	1200
-- "CR2"	"Бомбардье CRJ-200"	2700
-- "SU9"	"Сухой Суперджет-100"	3000
-- "733"	"Боинг 737-300"	4200
-- "321"	"Аэробус A321-200"	5600
-- "320"	"Аэробус A320-200"	5700
-- "319"	"Аэробус A319-100"	6700
-- "763"	"Боинг 767-300"	7900
-- "773"	"Боинг 777-300"	11100

-- select a.model, sum(a.range) over (order by a.range) from aircrafts as a;
-- select a.model, sum(a.range) over (partition by left(a.model, strpos(a.model, ' ') - 1) order by a.range) from aircrafts as a;


-- 16.
-- select max(range) filter (where a.model not like 'Боинг%') from aircrafts as a;
-- select avg(range) filter (where a.range < 5000) from aircrafts as a;


-- 17.
-- select a.aircraft_code,
-- 	a.model, 
-- 	s.fare_conditions,
-- 	count(s.*)
-- from aircrafts as a
-- join seats as s on a.aircraft_code = s.aircraft_code
-- group by 1, 2, 3
-- order by 2;


-- 18.
-- select a.aircraft_code, a.model, r.aircraft_code, count(r.*), round(count(r.*) / (select count(*) from routes)::numeric, 3 ) as fraction 
-- from aircrafts as a
-- left join routes as r on a.aircraft_code = r.aircraft_code
-- group by 1,2,3
-- order by fraction desc;


-- 19.
-- with recursive ranges (min_sum, max_sum, iteration) as (
-- 	values (0, 100_000, 0), (100_000, 200_000, 0), (200_000, 300_000, 0)
-- 	-- union all
-- 	union
-- 	select min_sum + 100_000, max_sum + 100_000, iteration + 1
-- 	from ranges
-- 	where max_sum < (select max(total_amount) from bookings)
-- )
-- select * from ranges;


-- 20.
-- with recursive ranges (min_sum, max_sum) as (
-- 	values (0, 100_000)
-- 	union
-- 	select min_sum + 100_000, max_sum + 100_000
-- 	from ranges
-- 	where (max_sum < (select max(total_amount) from bookings))
-- )

-- select r.min_sum, r.max_sum, count(b.*)
-- from bookings b
-- right join ranges r on b.total_amount >= r.min_sum and b.total_amount < r.max_sum
-- group by 1,2
-- order by 1;


-- 21.
-- select a.city 
-- from airports a
-- where not exists (select 1 from routes r where r.departure_city like 'Москва' and arrival_city = a.city)
-- and a.city <> 'Москва'
-- order by city;


-- select city from airports where city <> 'Москва'
-- except
-- select arrival_city from routes where departure_city like 'Москва' order by city;


-- 22.
-- select a2.city, a2.airport_code, a2.airport_name
-- from (
-- 	select city
-- 	from airports
-- 	group by city
-- 	having count(*) > 1
-- ) as a1
-- join airports as a2 on a1.city = a2.city
-- order by 1,2;


-- 23.
-- select count(*) from (select distinct city from airports) as a1 join (select distinct city from airports) as a2 on a1.city <> a2.city;
-- select count(*) from (select distinct city from airports) as a1, (select distinct city from airports) as a2 where a1.city <> a2.city;


-- 24.
-- select * from aircrafts where range > any (select unnest(array[7000, 11000]) offset 1 limit 1);
-- select * from aircrafts where range > all (select unnest(array[3000, 5000])) order by range desc limit 3;


-- 25.
-- with ticket_seats as (
-- 	select
-- 		f.flight_id,
-- 		f.flight_no,
-- 		f.departure_city,
-- 		f.arrival_city,
-- 		f.aircraft_code,
-- 		count(tf.ticket_no) as fact_passengers,
-- 		(select (count(s.seat_no)) from seats s where s.aircraft_code = f.aircraft_code) as total_seats
-- 	from flights_v f
-- 	join ticket_flights tf on f.flight_id = tf.flight_id
-- 	where f.status = 'Arrived'
-- 	group by 1,2,3,4,5
-- )
-- select
-- 	ts.departure_city,
-- 	ts.arrival_city,
-- 	sum(ts.fact_passengers) as sum_pass,
-- 	sum(ts.total_seats) as sum_seats,
-- 	round(sum(ts.fact_passengers::numeric)/ sum(ts.total_seats)::numeric, 2) as fraction
-- from ticket_seats ts
-- group by 1,2
-- order by 1;


-- 26.
select * from flights_v where departure_city = 'Кемерово' and arrival_city = 'Москва' and actual_arrival_local < bookings.now();
select
	t.passenger_name,
	b.seat_no
from 
	ticket_flights tf
	join tickets t on tf.ticket_no = t.ticket_no
	join boarding_passes b on tf.ticket_no = b.ticket_no and tf.flight_id = b.flight_id
	where tf.flight_id = 27584
order by t.passenger_name;


select 
	t.passenger_name,
	left(t.passenger_name, strpos(t.passenger_name, ' ') - 1) as firstname,
	right(t.passenger_name, length(t.passenger_name) - strpos(t.passenger_name, ' ')) as lastname,
	b.seat_no
from 
	ticket_flights tf
	join tickets t on tf.ticket_no = t.ticket_no
	join boarding_passes b on tf.ticket_no = b.ticket_no and tf.flight_id = b.flight_id
	where tf.flight_id = 27584
order by 2,3;


with passengers_info as (
	select 
		t.passenger_name,
		left(t.passenger_name, strpos(t.passenger_name, ' ') - 1) as firstname,
		right(t.passenger_name, length(t.passenger_name) - strpos(t.passenger_name, ' ')) as lastname,
		b.seat_no,
		tf.fare_conditions,
		t.contact_data -> 'email' as email
	from 
		ticket_flights tf
		join tickets t on tf.ticket_no = t.ticket_no
		join boarding_passes b on tf.ticket_no = b.ticket_no and tf.flight_id = b.flight_id
		where tf.flight_id = 27584
	)

select 
	s.seat_no,
	p.fare_conditions,
	p.passenger_name,
	p.email
from seats s
left join passengers_info as p on s.seat_no = p.seat_no
where s.aircraft_code = 'SU9'
order by left(s.seat_no, length(s.seat_no)-1)::integer, right(s.seat_no, 1);
	
	 
