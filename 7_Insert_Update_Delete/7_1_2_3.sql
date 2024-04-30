-- 7.1 Row Insertions into a table'
drop table if exists aircrafts_tmp;
create temp table if not exists aircrafts_tmp as select * from aircrafts with no data;
alter table aircrafts_tmp add primary key (aircraft_code); 
alter table aircrafts_tmp add unique (model);
-- OR
-- create temp table aircrafts_tmp (like aircrafts including constraints including indexes);


drop table if exists aircrafts_log;
create temp table if not exists aircrafts_log as select * from aircrafts with no data;
alter table aircrafts_log add column when_add timestamp default current_timestamp;
alter table aircrafts_log  add column operation text;

with add_row as (
	insert into aircrafts_tmp 
	select * from aircrafts
	returning *
)

insert into aircrafts_log
select ar.aircraft_code, ar.model, ar.range, current_timestamp, 'INSERT' from add_row ar;

insert into aircrafts_tmp select * from aircrafts returning *;
-- "773"	"Боинг 777-300"	11100
-- "763"	"Боинг 767-300"	7900
-- "SU9"	"Сухой Суперджет-100"	3000
-- "321"	"Аэробус A321-200"	5600
-- "319"	"Аэробус A319-100"	6700
-- "733"	"Боинг 737-300"	4200
-- "CN1"	"Сессна 208 Караван"	1200
-- "CR2"	"Бомбардье CRJ-200"	2700
-- "320"	"Аэробус A320-200"	5700



-- There's the keywords "on conflict". If there's a conflict while inserting this keyword allows to solve the problem in the following two ways:
-- 1. Skip the row insertion operation. The keyword is 'on conflict do nothing'
-- 2. Replace the old row with the new one.

-- DO NOTHING
with first_add_repettitive_row as (
	insert into aircrafts_tmp
	values ('SU9', 'Сухой Суперджет-100', 3000)
	on conflict DO NOTHING -- Checks are performed on primary keys and unique constraints
	returning *
)

insert into aircrafts_log
select
	first_add_repettitive_row.aircraft_code,
	first_add_repettitive_row.model,
	first_add_repettitive_row.range,
	current_timestamp,
	'INSERT'
from first_add_repettitive_row;
-- INSERT 0 0

with second_add_repettitive_row as (
	insert into aircrafts_tmp
	values ('SU9', 'Сухой Суперхуй-666', 3000), ('HU1', 'Сухой Суперхуй-666', 3000) -- The first value will be skipped and the second will not
	on conflict (aircraft_code) DO NOTHING -- Checks are performed on the specific column
	returning *
)

insert into aircrafts_log
select
	second_add_repettitive_row.aircraft_code,
	second_add_repettitive_row.model,
	second_add_repettitive_row.range,
	current_timestamp,
	'INSERT'
from second_add_repettitive_row;
-- INSERT 0 1

-- DO UPDATE
with third_add_repettitive_row as (
	insert into aircrafts_tmp
	values ('SU9', 'Сухой Суперхуй', 3500)
	on conflict ON CONSTRAINT aircrafts_tmp_pkey
	DO UPDATE set model = excluded.model, range = excluded.range -- excluded is the data of the inserted string
	returning *
)
	
insert into aircrafts_log
select
	third_add_repettitive_row.aircraft_code,
	third_add_repettitive_row.model,
	third_add_repettitive_row.range,
	current_timestamp,
	'INSERT'
from third_add_repettitive_row;
-- INSERT 0 1

select * from aircrafts_tmp;


-- COPY command
copy aircrafts_tmp from '/Users/dmitriymamykin/Desktop/aircrafts.txt' with (format csv);
copy aircrafts_tmp to '/Users/dmitriymamykin/Desktop/aircrafts_copy.txt' with (format csv); -- There's insertion checks too


-- 7.2 Rows Updating
with update_row as (
	update aircrafts_tmp
	set range = range * 1.2
	where model ~'^Бом'
	returning * -- Return all the changes
)

insert into aircrafts_log
select
	ur.aircraft_code,
	ur.model,
	ur.range,
	current_timestamp,
	'UPDATE'
from update_row ur;

select * from aircrafts_log where model ~'^Бом' order by when_add;
-- "CR2"	"Бомбардье CRJ-200"	2700	"2024-04-29 14:27:24.547209"	"INSERT"
-- "CR2"	"Бомбардье CRJ-200"	3240	"2024-04-29 14:27:24.547209"	"UPDATE"

drop table if exists tickets_directions;
create temp table if not exists tickets_directions as select distinct departure_city, arrival_city from routes;
alter table tickets_directions add column last_ticket_time timestamp;
alter table tickets_directions add column tickets_num integer default 0;
select * from tickets_directions;

drop table if exists ticket_flights_tmp;
create temp table if not exists ticket_flights_tmp as select * from ticket_flights with no data;
alter table ticket_flights_tmp add primary key (ticket_no, flight_id);

with sell_ticket as (
	insert into ticket_flights_tmp (ticket_no, flight_id, fare_conditions, amount) values ('1234567890123', 7757, 'Economy', 3400)
	returning *
)

update tickets_directions td
set last_ticket_time = current_timestamp, tickets_num = tickets_num + 1
where (td.departure_city, td.arrival_city) = (select departure_city, arrival_city from flights_v where flight_id = (select flight_id from sell_ticket));

-- select * from tickets_directions;
with sell_ticket as (
	insert into ticket_flights_tmp (ticket_no, flight_id, fare_conditions, amount) values ('1234567890127', 30421, 'Economy', 3400)
	returning *
)
	
update tickets_directions td
set last_ticket_time = current_timestamp, tickets_num = tickets_num + 1
from flights_v f 
where td.departure_city = f.departure_city and td.arrival_city = f.arrival_city and f.flight_id = (select flight_id from sell_ticket);

select * from tickets_directions where tickets_num > 0;


-- 7.3 Deletion from the tables
with delete_row as (
	delete from aircrafts_tmp
	where model ~'^Бом'
	returning *
)

insert into aircrafts_log
select
	dr.aircraft_code,
	dr.model,
	dr.range,
	current_timestamp,
	'DELETE'
from delete_row dr;

select * from aircrafts_log where model like 'Бом%' order by when_add;
-- "CR2"	"Бомбардье CRJ-200"	2700	"2024-04-29 15:02:48.344023"	"INSERT"
-- "CR2"	"Бомбардье CRJ-200"	3240	"2024-04-29 15:02:48.344023"	"UPDATE"
-- "CR2"	"Бомбардье CRJ-200"	3240	"2024-04-29 15:02:48.344023"	"DELETE"

with min_ranges as (
	select
		aircraft_code,
	rank() over (partition by left(model, 6) order by range) as rank
	from aircrafts_tmp
	where model like 'Аэробус%' or model like 'Боинг%'
)
-- "733"	1
-- "763"	2
-- "773"	3
-- "321"	1
-- "320"	2
-- "319"	3

-- select * from min_ranges;

delete from aircrafts_tmp a
using min_ranges mr 
where a.aircraft_code = mr.aircraft_code and rank = 1
returning *;
-- "733"	"Боинг 737-300"	4200	"733"	1
-- "321"	"Аэробус A321-200"	5600	"321"	1


delete from aircrafts_tmp;
truncate aircrafts_tmp;