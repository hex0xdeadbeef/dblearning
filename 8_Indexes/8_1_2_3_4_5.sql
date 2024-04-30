-- -- 8.1 General info

-- drop index if exists test_airport_data_idx;
-- create index test_airport_data_idx on airports_data (airport_name);
-- -- CREATE INDEX

-- select count(*) from tickets where passenger_name ilike  'ivan ivanov';
-- -- 118 ms
-- drop index if exists test_tickets_idx;
-- create index test_tickets_idx on tickets (passenger_name);
-- -- 1 second 72 ms
-- select count(*) from tickets where passenger_name ilike 'ivan ivanov';
-- -- 58 ms


-- -- 8.2 Multiple attributes indexes
-- drop index if exists tickets_book_ref_test_key;
-- create index tickets_book_ref_test_key on tickets (book_ref);
-- -- 1 second 290 ms

-- select * from tickets order by book_ref limit 5;
-- -- 118 ms 

-- drop index if exists tickets_book_ref_test_key;
-- select * from tickets order by book_ref limit 5;
-- -- 141 ms

-- drop index if exists tickets_book_ref_test_key;
-- create index tickets_book_ref_test_key on tickets (book_ref asc nulls first);
-- select * from tickets order by book_ref limit 5;
-- -- 65 ms

-- drop index if exists tickets_book_ref_test_key;
-- create index tickets_book_ref_test_key on tickets (book_ref asc nulls last);
-- select * from tickets order by book_ref limit 5;
-- -- 65 ms


-- -- 8.3 Unique Indexes
-- drop index if exists aircrafts_unique_model_key;
-- create unique index aircrafts_unique_model_key on aircrafts_data (model);


-- -- 8.4 Indexes Based On Expressions
-- drop index if exists aircrafts_unique_model_key;
-- create unique index aircrafts_unique_model_key on aircrafts_data (lower((model -> 'ru')::text));
-- -- insert into aircrafts_data values ('123', '{"ru":"Сессна 208 КАРАВАН"}'::jsonb, 1300);
-- -- ERROR:  Key (lower((model -> 'ru'::text)::text))=("сессна 208 караван") already exists.duplicate key value violates unique constraint "aircrafts_unique_model_key" 


-- 8.5 Partial Indexes
select * from bookings where total_amount > 1_000_000 order by book_date desc;
-- 49 ms
drop index if exists bookings_book_date_part_key;
create index bookings_book_date_part_key on bookings (book_date) where total_amount > 1_000_000;
select * from bookings where total_amount > 1_000_000 order by book_date desc;
-- 26 ms

select * from bookings where total_amount > 1_100_000;
-- 46 ms
select * from bookings where total_amount > 900_000;
-- 43 ms