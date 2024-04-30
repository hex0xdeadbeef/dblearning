-- 7.1 Row Insertions into a table'
drop table if exists aircrafts_tmp;
create temp table if not exists aircrafts_tmp as select * from aircrafts with no data;
alter table aircrafts_tmp add primary key (aircraft_code); 
alter table aircrafts_tmp add unique (model);

drop table if exists aircrafts_log;
create temp table if not exists aircrafts_log as select * from aircrafts with no data;
alter table aircrafts_log add column when_add timestamp default current_timestamp;
alter table aircrafts_log  add column operation text;

-- 2.
with add_row as (
	insert into aircrafts_tmp 
	select * from aircrafts
	returning aircraft_code, model, range, current_timestamp, 'INSERT'
)
	
insert into aircrafts_log select * from add_row returning *;
-- "773"	"Боинг 777-300"	11100
-- "763"	"Боинг 767-300"	7900
-- "SU9"	"Сухой Суперджет-100"	3000
-- "321"	"Аэробус A321-200"	5600
-- "319"	"Аэробус A319-100"	6700
-- "733"	"Боинг 737-300"	4200
-- "CN1"	"Сессна 208 Караван"	1200
-- "CR2"	"Бомбардье CRJ-200"	2700
-- "320"	"Аэробус A320-200"	5700

-- 3.
-- insert into aircrafts_tmp select * from aircrafts returning *;
-- "773"	"Боинг 777-300"	11100
-- "763"	"Боинг 767-300"	7900
-- "SU9"	"Сухой Суперджет-100"	3000
-- "321"	"Аэробус A321-200"	5600
-- "319"	"Аэробус A319-100"	6700
-- "733"	"Боинг 737-300"	4200
-- "CN1"	"Сессна 208 Караван"	1200
-- "CR2"	"Бомбардье CRJ-200"	2700
-- "320"	"Аэробус A320-200"	5700


-- 4.
drop table if exists seats_tmp;
create temp table if not exists seats_tmp as select * from seats with no data;
alter table seats_tmp add constraint seats_tmp_pkey primary key (aircraft_code, seat_no);

insert into seats_tmp (aircraft_code, seat_no, fare_conditions) values ('SU9', '10A', 'Economy'), ('SU9', '10F', 'Business');

with first_repetitive_insert as (
	insert into seats_tmp
	values ('SU9', '10A', 'Economy')
	on conflict (aircraft_code, seat_no) do nothing
	returning *
)

select * from first_repetitive_insert;

with second_repetitive_insert as (
	insert into seats_tmp
	values ('SU9', '10A', 'Economy')
	on conflict on constraint seats_tmp_pkey do nothing
	returning *
)

select * from second_repetitive_insert; 

-- 5.
with third_repetitive_insertion as (
	insert into seats_tmp as s
	values ('SU9', '10A', 'Comfort')
	on conflict on constraint seats_tmp_pkey do update
	set fare_conditions = excluded.fare_conditions where s.seat_no = '10A'
	returning *
)

select * from third_repetitive_insertion;
select * from seats_tmp;


-- 6.


-- 7.
-- copy aircrafts_tmp from '/Users/dmitriymamykin/Desktop/aircrafts.csv' with (format csv);
-- ERROR:  Key (aircraft_code)=(SU9) already exists.duplicate key value violates unique constraint "aircrafts_tmp_pkey" 
-- ERROR:  duplicate key value violates unique constraint "aircrafts_tmp_pkey"


-- 8.
-- select
-- 	flight_no,
-- 	flight_id, 
-- 	departure_city,
-- 	arrival_city, 
-- 	scheduled_departure 
-- from flights_v
-- where scheduled_departure between bookings.now() and bookings.now() + '15 days'::interval
-- and (departure_city, arrival_city) in
-- (
-- 	('Красноярск', 'Москва'),
-- 	('Москва', 'Сочи'),
-- 	('Сочи', 'Москва'),
-- 	('Сочи', 'Красноярск')
-- )
-- order by departure_city, arrival_city, scheduled_departure;


-- | departure_city | arrival_city | last_ticket_time | tickets_num | fare_conditions |
drop table if exists tickets_directions;
create temp table if not exists tickets_directions as select distinct departure_city, arrival_city from routes;
alter table tickets_directions add column last_ticket_time timestamp;
alter table tickets_directions add column tickets_num integer default 0;
alter table tickets_directions add column fare_conditions text default 'Economy' not null check(length(fare_conditions) > 3);

-- | ticket_no | flight_id | fare_conditions | amount |
drop table if exists ticket_flights_tmp;
create temp table if not exists ticket_flights_tmp as select * from ticket_flights with no data;
alter table ticket_flights_tmp add primary key (ticket_no, flight_id);

with sell_tickets as (
	insert into ticket_flights_tmp (ticket_no, flight_id, fare_conditions, amount)
	values 
		('1234567890123', 13829, 'Comfort', 10500),
		('1234567890123', 4728, 'Economy', 3400),
		('1234567890123', 30523, 'Business', 3400),
		('1234567890123', 7757, 'Economy', 3400),
		('1234567890123', 30829, 'Comfort', 12800)
	returning *
)

update tickets_directions td
set last_ticket_time = current_timestamp,
	tickets_num = tickets_num + (select 
	count(*) 
	from sell_tickets st, flights_v f
	where st.flight_id = f.flight_id
	and f.departure_city = td.departure_city
	and f.arrival_city = td.arrival_city
	)
where (td.departure_city, td.arrival_city) in (select departure_city, arrival_city from flights_v where flight_id in (select flight_id from sell_tickets));

select 
	departure_city as dep_city,
	arrival_city as arr_city,
	last_ticket_time,
	tickets_num as num
from tickets_directions
where tickets_num > 0
order by departure_city, arrival_city;
-- "Сочи"	"Москва"	"2024-04-29 17:58:14.854783"	1
-- "Сочи"	"Красноярск"	"2024-04-29 17:58:14.854783"	1
-- "Москва"	"Сочи"	"2024-04-29 17:58:14.854783"	2
-- "Красноярск"	"Москва"	"2024-04-29 17:58:14.854783"	1

select * from ticket_flights_tmp;
-- "1234567890123"	13829	"Comfort"	10500.00
-- "1234567890123"	4728	"Economy"	3400.00
-- "1234567890123"	30523	"Business"	3400.00
-- "1234567890123"	7757	"Economy"	3400.00
-- "1234567890123"	30829	"Comfort"	12800.00
-- "1234567890123"	30829	"Economy"	12800.00


-- 9.
with aircrafts_seats as (
	select
	aircraft_code, 
	model, 
	seats_num,
	rank() over (partition by left(model, strpos(model, ' ') - 1) order by seats_num)
	from (select 
				a.aircraft_code, 
				a.model, count(*) as seats_num 
			from aircrafts_tmp as a, seats as s 
			where 
				a.aircraft_code = s.aircraft_code
			group by 1,2)
)


-- delete from aircrafts_tmp as a 
-- 	using aircrafts_seats as a_s 
-- 	where 
-- 		a.aircraft_code = a_s.aircraft_code 
-- 		and a_s.rank = 1 
-- 		and left(a.model, strpos(a.model, ' ') - 1) in ('Боинг', 'Аэробус');

delete from aircrafts_tmp as a 
	where exists (
	select 1 
	from aircrafts_seats as a_s
	where 
		rank = 1
		and left(a_s.model, strpos(a_s.model, ' ')-1) in ('Боинг', 'Аэробус')
		and a.aircraft_code = a_s.aircraft_code
	)
	returning *;

drop table if exists seats_tmp;
create temp table if not exists seats_tmp as select * from seats with no data;
alter table seats_tmp add constraint seats_tmp_pkey primary key (aircraft_code, seat_no);

