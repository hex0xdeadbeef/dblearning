-- 5.4 Views
-- create view seats_by_fare_conditions as
	-- select aircraft_code, fare_conditions_code, count(*)
	-- from seats
	-- group by aircraft_code, fare_conditions_code
	-- order by aircraft_code, fare_conditions_code;

-- select * from seats_by_fare_conditions;

-- create or replace view seats_by_fare_conditions as
-- 	select aircraft_code, fare_conditions_code, count (*) as seatscount
-- 	from seats
-- 	group by aircraft_code, fare_conditions_code
-- 	order by aircraft_code, fare_conditions_code;
-- ERROR:  cannot change name of view column "customcount" to "seatscount"

-- alter view seats_by_fare_conditions rename column count to customcount;
-- OR
-- drop view seats_by_fare_conditions;
-- create or replace view seats_by_fare_conditions as
-- 	select aircraft_code, fare_conditions_code, count (*) as seatscount
-- 	from seats
-- 	group by aircraft_code, fare_conditions_code
-- 	order by aircraft_code, fare_conditions_code;
-- select * from seats_by_fare_conditions;
-- OR
-- drop view seats_by_fare_conditions;
-- create or replace view seats_by_fare_conditions (code, fare_cond, seats_num) as
-- 	select aircraft_code, fare_conditions_code, count(*)
-- 	from seats
-- 	group by aircraft_code, fare_conditions_code
-- 	order by aircraft_code, fare_conditions_code;
-- select * from seats_by_fare_conditions;


-- drop view if exists flights_v;

-- refresh materialized view routes -- "refresh materialized view" is used to provide the materialized view with data collected with the request
-- body

-- drop materialized view routes if exists;


-- DB Schemas
show search_path; -- "public"
set search_path = bookings;
-- set search_path = default;
set search_path = bookings, public;
-- show search_path; -- "bookings, public"

-- select current_schema; -- "bookings"

