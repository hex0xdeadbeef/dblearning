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
-- cross join makes the cartesian's product explicitly without considering the condition

select a.aircraft_code, a.model, count(*) from routes r, aircrafts a where a.aircraft_code = r.aircraft_code group by a.aircraft_code, a.model order by count(*) desc;
select a.aircraft_code, a.model, count(*) from aircrafts as a join routes as r on a.aircraft_code = r.aircraft_code group by a.aircraft_code, a.model order by count(*) desc ;
-- select count(*) from (select a.aircraft_code, a.model, count(*) from aircrafts as a join routes as r on a.aircraft_code = r.aircraft_code group by a.aircraft_code, a.model); -- 8
-- select count(*) from aircrafts; -- 9

select a.aircraft_code, a.model, r.aircraft_code, count(r.aircraft_code) from aircrafts a left join routes r on a.aircraft_code = r.aircraft_code
	group by 1,2,3
	order by 4 desc;
-- ... left join ... on "condition" is used to search the coresspondances between left side table and right side table. If there are no correspondances for the
-- left side row, the right side attr will have the null value.

select r.aircraft_code, a.model, a.aircraft_code, count(r.aircraft_code) from aircrafts a right join routes r on a.aircraft_code = r.aircraft_code
	group by 1,2,3
	order by 4 desc;
-- -||- for the right side