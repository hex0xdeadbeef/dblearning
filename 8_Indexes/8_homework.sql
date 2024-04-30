-- -- 1.
-- drop table if exists insertion_test;
-- create temp table insertion_test (
-- 	firstname text,
-- 	lastname text
-- );

-- create unique index on insertion_test (firstname, lastname);
-- insert into insertion_test values ('Dmitriy', null);
-- insert into insertion_test values ('Dmitriy', null);

-- select * from insertion_test;
-- -- We cannot compare the "null" values, so these two strings are different from each other.


-- -- 2.
-- drop index if exists tickets_passenger_name_idx;
-- create index tickets_passenger_name_idx on tickets (lower(passenger_name));

-- select * from tickets where passenger_name = 'ivan ivanov';
-- -- The time reducing is performed because of cahcing.


-- -- 3.
-- select count(*) from ticket_flights where fare_conditions = 'Economy';
-- -- 920793
-- -- 57 ms

-- select count(*) from ticket_flights where fare_conditions = 'Comfort';
-- -- 17291 rows
-- -- 48 ms

-- select count(*) from ticket_flights where fare_conditions = 'Business';
-- -- 107642 rows
-- -- 50 ms

-- drop index if exists ticket_flights_fare_conditions_idx;
-- create index ticket_flights_fare_conditions_idx on ticket_flights (fare_conditions);
-- select count(*) from ticket_flights where fare_conditions = 'Economy';
-- -- 41 ms

-- select count(*) from ticket_flights where fare_conditions = 'Comfort';
-- -- 21 ms

-- select count(*) from ticket_flights where fare_conditions = 'Business';
-- -- 42 ms

-- -- The speed of selecting rows while using indexes is dependent on the fraction of rows. It might be spoiled if the planner make a mistake.

-- 4.


-- 5.


-- 6.


-- 7.


-- 8.
drop index if exists bookings_book_date_part_key;
create index bookings_book_date_part_key on bookings (book_date) where total_amount > 1_000_000;
select * from bookings where total_amount > 1_000_000;
-- 20 ms.

drop index if exists bookings_book_date_part_key;
create index bookings_book_date_part_key on bookings (book_date);
select * from bookings where total_amount > 1_000_000;
-- 26 ms.



