5.1 && 5.2
create table bookings.airports (
	airport_code 	char(3)	not null, -- Airport code
	airpott_name	text 	not null, -- Airport name
	city			text	not null, -- A city
	longtitude		float	not null, -- Airport's coordinate: longtitude
	latitude		float	not null, -- Airport's coordinate: latitude
	timezone		text	not null,
	
	primary key (airport_code)
);

create table bookings.flights (
	flight_id serial not null,
	flight_no char(6) not null, 
	
	scheduled_departure timestamptz not null,
	scheduled_arrival timestamptz not null,
	
	departure_airport char(3) not null,
	arrival_airport char(3) not null,
	
	status varchar(20) not null, 
	
	aircraft_code char(3) not null,
	
	actual_departure timestamptz,
	actual_arrival timestamptz, 

	check (scheduled_arrival > scheduled_departure), 
	check (status in ('On Time', 'Delayed', 'Departed', 'Arrived', 'Scheduleed', 'Canceled')),
	check (actual_arrival is null or (actual_departure is not null and actual_arrival is not null and actual_arrival > actual_departure)),

	primary key (flight_id),
	unique (flight_no, scheduled_departure),

	foreign key (aircraft_code) references public.aircrafts (aircraft_code),
	foreign key (departure_airport) references bookings.airports (airport_code),
	foreign key (arrival_airport) references bookings.airports (airport_code)
)

create table bookings.bookings (
	book_ref char(6) not null,
	book_date timestamptz not null, 
	total_amount numeric(10,2) not null,

	primary key (book_ref)
)

create table bookings.tickets (
	ticket_no char(13) not null,

	book_ref char(6) not null, 

	passenger_id varchar(20) not null,
	passenger_name text not null,

	contact_data jsonb,

	primary key (ticket_no),
	foreign key (book_ref) references bookings.bookings(book_ref)
	
)


create table bookings.ticket_flights (
	ticket_no char(13) not null, 

	flight_id integer not null, 

	fare_conditions varchar(10) not null, 

	amount numeric(10, 2), 

	check (amount >= 0),
	check (fare_conditions in ('Economy', 'Comfort', 'Business')),

	primary key (ticket_no, flight_id),
	foreign key (flight_id) references bookings.flights (flight_id),
	foreign key (ticket_no) references bookings.tickets (ticket_no)
)

create table bookings.boarding_passes (
	ticket_no char(13) not null,
	
	flight_id integer not null,

	boarding_no integer not null,

	seat_no varchar(4) not null, 

	primary key (ticket_no, flight_id), 

	unique(flight_id, boarding_no),
	unique(flight_id, seat_no),

	foreign key (ticket_no, flight_id) references bookings.ticket_flights(ticket_no, flight_id)
)

There is the command for table deletion "DROP TABLE schemaname.tablename"

If the table is referenced by others one we shoud use the command "DROP TABLE schemaname.tablename CASCADE". After using this command the corr-
esponding foreign keys of the referencing tables will be removed.

If we know that there might be an attempt to delete an existing table we can use "DROP TABLE IF EXISTS schemaname.tablename CASCADE".

alter table bookings.airpots 
create table bookings.airports (
	airport_code 	char(3)	not null, -- Airport code
	airpott_name	text 	not null, -- Airport name
	city			text	not null, -- A city
	longtitude		float	not null, -- Airport's coordinate: longtitude
	latitude		float	not null, -- Airport's coordinate: latitude
	timezone		text	not null,
	
	primary key (airport_code)
);

create table bookings.flights (
	flight_id serial not null,
	flight_no char(6) not null, 
	
	scheduled_departure timestamptz not null,
	scheduled_arrival timestamptz not null,
	
	departure_airport char(3) not null,
	arrival_airport char(3) not null,
	
	status varchar(20) not null, 
	
	aircraft_code char(3) not null,
	
	actual_departure timestamptz,
	actual_arrival timestamptz, 

	check (scheduled_arrival > scheduled_departure), 
	check (status in ('On Time', 'Delayed', 'Departed', 'Arrived', 'Scheduleed', 'Canceled')),
	check (actual_arrival is null or (actual_departure is not null and actual_arrival is not null and actual_arrival > actual_departure)),

	primary key (flight_id),
	unique (flight_no, scheduled_departure),

	foreign key (aircraft_code) references public.aircrafts (aircraft_code),
	foreign key (departure_airport) references bookings.airports (airport_code),
	foreign key (arrival_airport) references bookings.airports (airport_code)
)

create table bookings.bookings (
	book_ref char(6) not null,
	book_date timestamptz not null, 
	total_amount numeric(10,2) not null,

	primary key (book_ref)
)

create table bookings.tickets (
	ticket_no char(13) not null,

	book_ref char(6) not null, 

	passenger_id varchar(20) not null,
	passenger_name text not null,

	contact_data jsonb,

	primary key (ticket_no),
	foreign key (book_ref) references bookings.bookings(book_ref)
	
)


create table bookings.ticket_flights (
	ticket_no char(13) not null, 

	flight_id integer not null, 

	fare_conditions varchar(10) not null, 

	amount numeric(10, 2), 

	check (amount >= 0),
	check (fare_conditions in ('Economy', 'Comfort', 'Business')),

	primary key (ticket_no, flight_id),
	foreign key (flight_id) references bookings.flights (flight_id),
	foreign key (ticket_no) references bookings.tickets (ticket_no)
)

create table bookings.boarding_passes (
	ticket_no char(13) not null,
	
	flight_id integer not null,

	boarding_no integer not null,

	seat_no varchar(4) not null, 

	primary key (ticket_no, flight_id), 

	unique(flight_id, boarding_no),
	unique(flight_id, seat_no),

	foreign key (ticket_no, flight_id) references bookings.ticket_flights(ticket_no, flight_id)
)

There is the command for table deletion "DROP TABLE schemaname.tablename"

If the table is referenced by others one we shoud use the command "DROP TABLE schemaname.tablename CASCADE". After using this command the corr-
esponding foreign keys of the referencing tables will be removed.

If we know that there might be an attempt to delete an existing table we can use "DROP TABLE IF EXISTS schemaname.tablename CASCADE".

create table bookings.airports (
	airport_code 	char(3)	not null, -- Airport code
	airpott_name	text 	not null, -- Airport name
	city			text	not null, -- A city
	longtitude		float	not null, -- Airport's coordinate: longtitude
	latitude		float	not null, -- Airport's coordinate: latitude
	timezone		text	not null,
	
	primary key (airport_code)
);

create table bookings.flights (
	flight_id serial not null,
	flight_no char(6) not null, 
	
	scheduled_departure timestamptz not null,
	scheduled_arrival timestamptz not null,
	
	departure_airport char(3) not null,
	arrival_airport char(3) not null,
	
	status varchar(20) not null, 
	
	aircraft_code char(3) not null,
	
	actual_departure timestamptz,
	actual_arrival timestamptz, 

	check (scheduled_arrival > scheduled_departure), 
	check (status in ('On Time', 'Delayed', 'Departed', 'Arrived', 'Scheduleed', 'Canceled')),
	check (actual_arrival is null or (actual_departure is not null and actual_arrival is not null and actual_arrival > actual_departure)),

	primary key (flight_id),
	unique (flight_no, scheduled_departure),

	foreign key (aircraft_code) references public.aircrafts (aircraft_code),
	foreign key (departure_airport) references bookings.airports (airport_code),
	foreign key (arrival_airport) references bookings.airports (airport_code)
)

create table bookings.bookings (
	book_ref char(6) not null,
	book_date timestamptz not null, 
	total_amount numeric(10,2) not null,

	primary key (book_ref)
)

create table bookings.tickets (
	ticket_no char(13) not null,

	book_ref char(6) not null, 

	passenger_id varchar(20) not null,
	passenger_name text not null,

	contact_data jsonb,

	primary key (ticket_no),
	foreign key (book_ref) references bookings.bookings(book_ref)
	
)


create table bookings.ticket_flights (
	ticket_no char(13) not null, 

	flight_id integer not null, 

	fare_conditions varchar(10) not null, 

	amount numeric(10, 2), 

	check (amount >= 0),
	check (fare_conditions in ('Economy', 'Comfort', 'Business')),

	primary key (ticket_no, flight_id),
	foreign key (flight_id) references bookings.flights (flight_id),
	foreign key (ticket_no) references bookings.tickets (ticket_no)
)

create table bookings.boarding_passes (
	ticket_no char(13) not null,
	
	flight_id integer not null,

	boarding_no integer not null,

	seat_no varchar(4) not null, 

	primary key (ticket_no, flight_id), 

	unique(flight_id, boarding_no),
	unique(flight_id, seat_no),

	foreign key (ticket_no, flight_id) references bookings.ticket_flights(ticket_no, flight_id)
)

There is the command for table deletion "DROP TABLE schemaname.tablename"

If the table is referenced by others one we shoud use the command "DROP TABLE schemaname.tablename CASCADE". After using this command the corr-
esponding foreign keys of the referencing tables will be removed.

If we know that there might be an attempt to delete an existing table we can use "DROP TABLE IF EXISTS schemaname.tablename CASCADE".

	create table bookings.airports (
	airport_code 	char(3)	not null, -- Airport code
	airpott_name	text 	not null, -- Airport name
	city			text	not null, -- A city
	longtitude		float	not null, -- Airport's coordinate: longtitude
	latitude		float	not null, -- Airport's coordinate: latitude
	timezone		text	not null,
	
	primary key (airport_code)
);

create table bookings.flights (
	flight_id serial not null,
	flight_no char(6) not null, 
	
	scheduled_departure timestamptz not null,
	scheduled_arrival timestamptz not null,
	
	departure_airport char(3) not null,
	arrival_airport char(3) not null,
	
	status varchar(20) not null, 
	
	aircraft_code char(3) not null,
	
	actual_departure timestamptz,
	actual_arrival timestamptz, 

	check (scheduled_arrival > scheduled_departure), 
	check (status in ('On Time', 'Delayed', 'Departed', 'Arrived', 'Scheduleed', 'Canceled')),
	check (actual_arrival is null or (actual_departure is not null and actual_arrival is not null and actual_arrival > actual_departure)),

	primary key (flight_id),
	unique (flight_no, scheduled_departure),

	foreign key (aircraft_code) references public.aircrafts (aircraft_code),
	foreign key (departure_airport) references bookings.airports (airport_code),
	foreign key (arrival_airport) references bookings.airports (airport_code)
)

create table bookings.bookings (
	book_ref char(6) not null,
	book_date timestamptz not null, 
	total_amount numeric(10,2) not null,

	primary key (book_ref)
)

create table bookings.tickets (
	ticket_no char(13) not null,

	book_ref char(6) not null, 

	passenger_id varchar(20) not null,
	passenger_name text not null,

	contact_data jsonb,

	primary key (ticket_no),
	foreign key (book_ref) references bookings.bookings(book_ref)
	
)


create table bookings.ticket_flights (
	ticket_no char(13) not null, 

	flight_id integer not null, 

	fare_conditions varchar(10) not null, 

	amount numeric(10, 2), 

	check (amount >= 0),
	check (fare_conditions in ('Economy', 'Comfort', 'Business')),

	primary key (ticket_no, flight_id),
	foreign key (flight_id) references bookings.flights (flight_id),
	foreign key (ticket_no) references bookings.tickets (ticket_no)
)

create table bookings.boarding_passes (
	ticket_no char(13) not null,
	
	flight_id integer not null,

	boarding_no integer not null,

	seat_no varchar(4) not null, 

	primary key (ticket_no, flight_id), 

	unique(flight_id, boarding_no),
	unique(flight_id, seat_no),

	foreign key (ticket_no, flight_id) references bookings.ticket_flights(ticket_no, flight_id)
)

There is the command for table deletion "DROP TABLE schemaname.tablename"

If the table is referenced by others one we shoud use the command "DROP TABLE schemaname.tablename CASCADE". After using this command the corr-
esponding foreign keys of the referencing tables will be removed.

If we know that there might be an attempt to delete an existing table we can use "DROP TABLE IF EXISTS schemaname.tablename CASCADE".



5.3 Table Modifications
insert into bookings.airports values ('AA1', 'Domodedovo', 'Moscow', 13.12, 11.10, 'UTC+04');
alter table bookings.airports  add column speed integer not null check (speed >= 300);
ERROR:  column "speed" of relation "airports" contains null values 
delete from bookings.airports where airport_code = 'AA1';

alter table aircrafts add column speed integer;

update aircrafts set speed = 807 where aircraft_code = '733';
update aircrafts set speed = 807 where aircraft_code = '773';
update aircrafts set speed = 851 where aircraft_code = '763';
update aircrafts set speed = 905 where aircraft_code = '773';
update aircrafts set speed = 840 where aircraft_code in ('319', '320', '321');
update aircrafts set speed = 786 where aircraft_code = 'CR2';
update aircrafts set speed = 341 where aircraft_code = 'CN1';
update aircrafts set speed = 830 where aircraft_code = 'SU9';

select * from aircrafts;

alter table aircrafts alter column speed set not null;
alter table aircrafts add check (speed >= 300);

alter table aircrafts drop constraint aircrafts_speed_check;
alter table aircrafts drop column speed;


alter table bookings.airports
	alter column longtitude set data type numeric(5,2),
	alter column latitude set data type numeric(5,2);
select * from bookings.airports;


create table fare_conditions (
	fare_conditions_code integer, 
	fare_conditions_name varchar(10) not null,
	primary key (fare_conditions_code)
);
insert into fare_conditions values (1, 'Economy'), (2, 'Business'), (3, 'Comfort');
alter table seats drop constraint seats_fare_conditions_check,
alter column fare_conditions set data type integer
	using ( case when fare_conditions = 'Economy' then 1
				when fare_conditions = 'Business' then 2
				-- when fare_conditions = 'Comfort' then 3
				else 3	end
	);
alter table seats add foreign key (fare_conditions) references fare_conditions (fare_conditions_code);
alter table seats rename column fare_conditions to fare_conditions_code;
alter table seats rename constraint seats_fare_conditions_fkey to seats_fare_conditions_code_fkey;
alter table fare_conditions add unique(fare_conditions_name);