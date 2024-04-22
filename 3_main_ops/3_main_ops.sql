create table aircrafts (
	aircraft_code char(3) not null,
	model text not null,
	range integer not null,
	check (range > 0),
	primary key (aircraft_code)
);


select * from aircrafts;


select * from aircrafts order by model;
select * from aircrafts order by aircraft_code desc;


select * from aircrafts where range >= 4000 and range <= 10000 order by range desc;


update aircrafts set range = 3500 where aircraft_code = 'SU9';


insert into aircrafts (aircraft_code, model, range) values ('AA2', 'Bim-Bim-Bam-Bam Jet', 10000)
delete from aircrafts where aircraft_code = 'AA2'

create table characters (
	id integer,
	ch char(1)
	check (id >= 0),
	primary key (id)
)
insert into characters (id, ch) values (0, 'A'), (2, 'B'), (3, 'C')
delete from characters;
select * from characters;


create table seats (
	aircraft_code char(3) not null,
	seat_no varchar(4) not null,
	fare_conditions varchar(10) not null check (fare_conditions in ('Economy', 'Comfort', 'Business')),
	primary key (aircraft_code, seat_no),
	foreign key (aircraft_code) references aircrafts (aircraft_code) on delete cascade
);

insert into seats (aircraft_code, seat_no, fare_conditions) values ('123', '1B', 'Economy')
ERROR:  Key (aircraft_code)=(123) is not present in table "aircrafts".insert or update on table "seats" violates foreign key constraint "seats_aircraft_code_fkey"

select aircraft_code, count(*) from seats group by aircraft_code order by aircraft_code desc;
select aircraft_code, fare_conditions, count(*) from seats
	group by aircraft_code, fare_conditions
	order by aircraft_code desc;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into aircrafts (aircraft_code, model, range) values ('SU9', 'Bim-Bim-Bam-Bam Jet', 3500)
ERROR:  Key (aircraft_code)=(SU9) already exists.duplicate key value violates unique constraint "aircrafts_pkey"

update aircrafts set range = range * 2 where aircraft_code = 'SU9';
select * from aircrafts where aircraft_code = 'SU9';

delete from aircrafts where aircraft_code = 'XXX'
DELETE 0 -- Nothing has been deleted