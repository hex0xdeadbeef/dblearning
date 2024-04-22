4.1 Numeric types
select 0.1::real * 10 = 1.0::real -- false


create table serialnames (
	id serial not null,
	name varchar(10) not null,
	primary key (id)
)
insert into serialnames (name) values ('Dmitriy'), ('Kate'), ('Denis');
select * from serialnames;
drop table serialnames;

4.1 Symbolic types
select 'PostgreSQL';
select 'PGDAY''17';
select $$PGDAY'17$$
select E'PGDAY\n17';
select E'PGDAY\'17';

4.1 Date/Time types
select '2024-04-21'::date;
select 'Apr 21, 2024'::date;

select current_date;
select to_char(current_date, 'dd-mm-yyyy')

select '14:00:26'::time
select '25:22:13'::time;
ERROR:  date/time field value out of range: "25:22:13"
select '11:23:41 am'::time;
select '11:23:41 pm'::time;
select current_time;

select timestamp '2024-04-21 14:05:21';
select timestamptz '2024-04-21 14:05:21';
select current_timestamp;

select '1 year 2 months ago'::interval
select 'P0001-02-03T04:05:06'::interval
select ('2024-04-21'::timestamp - '2023-03-23'::timestamp)::interval

select current_time;
select current_date;
select current_timestamp;

select (date_trunc('second', current_timestamp));
select extract('mon' from current_timestamp);


4.4 Boolean type
select true::boolean;
select 'true'::boolean;
select 't'::boolean;
select 'yes'::boolean;
select 'y'::boolean;
select 'on'::boolean;
select '1'::boolean;

select 'false'::boolean;
select 'f'::boolean;
select 'no'::boolean;
select 'n'::boolean;
select 'off'::boolean;
select '0'::boolean;

select null::boolean;

create table databases(
	is_open_source boolean not null,
	dbms_name text not null
);
insert into databases (is_open_source, dbms_name) values (true, 'PostgreSQL'), (false, 'Oracle'), (true, 'MySQL'), (false, 'MS SQL Server');
select * from databases;
select * from databases where is_open_source = true;
select * from databases where is_open_source;


4.5 Arrays
create table pilots (
	pilot_name text not null,
	schedule integer[]
);

insert into pilots (pilot_name, schedule) values ('Ivan', '{1, 3, 5, 6, 7}'::integer[]),
	('Petr', '{1, 2, 5, 7}'::integer[]),
	('Pavel', '{2, 5}'::integer[]),
	('Boris', '{3, 5, 6}'::integer[]);

select * from pilots;
update pilots set schedule = schedule || 7 where pilot_name = 'Boris'
select * from pilots where pilot_name = 'Boris';

update pilots set schedule = array_append(schedule, 6) where pilot_name = 'Pavel'
update pilots set schedule = array_prepend(1, schedule) where pilot_name = 'Pavel';
select * from pilots where pilot_name = 'Pavel';

update pilots set schedule = array_remove(schedule, 5) where pilot_name = 'Ivan'
select * from pilots where pilot_name = 'Ivan';

update pilots set schedule[1] = 2, schedule[2] = 3 where pilot_name = 'Petr';
select * from pilots where pilot_name = 'Petr';
update pilots set schedule[1:2] = ARRAY[2, 3] where pilot_name = 'Pet	r';
select * from pilots;

select * from pilots where array_position(schedule, 3) is not null;
select * from pilots where array_position(schedule, 8) is not null;
select * from pilots where schedule @> '{1, 7}'::integer[];
select * from pilots where schedule && ARRAY[2, 5];
select * from pilots where not (schedule && ARRAY[2,5]);
select  unnest(schedule) as days_of_week from pilots where pilot_name = 'Ivan';

4.6 JSON Type
create table pilot_hobbies (
	pilot_name text not null,
	hobbies jsonb not null
);

insert into pilot_hobbies (pilot_name, hobbies)
	values ('Ivan', '{"sports":["football", "swimming"], "home_lib":true, "trips":3 }'::jsonb),
	('Petr', '{"sports":["tennis", "swimming"], "home_lib":true, "trips":2}'::jsonb),
	('Pavel', '{"sports":["swimming"], "home_lib":false, "trips":4}'::jsonb),
	('Boris', '{"sports":["football", "swimming", "tennis"], "home_lib":true, "trips":0}'::jsonb);

select * from pilot_hobbies;
select * from pilot_hobbies where hobbies @> '{"sports":["football"]}'::jsonb;
select pilot_name, hobbies -> 'sports' as sports from pilot_hobbies where hobbies -> 'sports' @> '["football"]'::jsonb;
select count(*) from pilot_hobbies
 where hobbies ? 'sport';
select count(*) from pilot_hobbies where hobbies ? 'sports';
update pilot_hobbies set hobbies = hobbies || '{"sports":["hockey"]}' where pilot_name = 'Boris';
select * from pilot_hobbies where pilot_name = 'Boris';
update pilot_hobbies set hobbies = jsonb_set(hobbies, '{sports, 1}', '"football"') where pilot_name = 'Boris';
update pilot_hobbies set hobbies = jsonb_set(hobbies, '{sports, 2}', '"tennis"') where pilot_name = 'Boris';
select * from pilot_hobbies where pilot_name = 'Boris';