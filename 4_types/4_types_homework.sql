1.
drop table test_numeric;
create table test_numeric (
	measurement numeric(5, 2),
	descr text
);

delete from test_numeric;
insert into test_numeric (measurement, descr) values (99.999, '1st measurement');
insert into test_numeric (measurement, descr) values (999.99, '2nd measurement');
-- insert into test_numeric (measurement, descr) values (999.9999, '3rd measurement');
-- ERROR:  A field with precision 5, scale 2 must round to an absolute value less than 10^3.numeric field overflow
insert into test_numeric (measurement, descr) values (999.9009, '3rd measurement');
insert into test_numeric (measurement, descr) values (999.1111, '4th measurement');
insert into test_numeric (measurement, descr) values (998.9999, '5th measurement');
select * from test_numeric;


2.
drop table test_numeric;
create table test_numeric (
	measurement numeric,
	descr text
);

insert into test_numeric (measurement, descr) values (1234567890.0987654321, '1st measurement');
insert into test_numeric (measurement, descr) values (1.5, '2nd measurement');
insert into test_numeric (measurement, descr) values (0.1234567890123456789, '3rd measurement');
insert into test_numeric (measurement, descr) values (1234567890, '4th measurement');
select * from test_numeric;


3.
select 'NaN'::numeric = 'NaN'::numeric; -- true
select 'NaN'::numeric > 10000; -- true


4.
select '5e-324'::double precision > '4e-324'::double precision; -- the precision for the double precision type is less than 15 numbers
select '5e-324'::double precision;
select '4e-324'::double precision;

5.
select 'Inf'::real = 'Inf'::double precision; -- true
select 'Inf'::real < 'Inf'::double precision; -- false
select 'Inf'::real > '1e37'::real; -- true
select '-Inf'::real < '1e-40'::real; -- true


6.
select 0.0::real * 'NaN'::real; -- NaN
select 'NaN'::real > 'Inf'::real;
select ''

7.
drop table test_serial;
create table test_serial (
	id serial,
	name text,
	check ( id > 0 ),
	primary key (id)
);

insert into test_serial (name)
	values ('Sovietskoy army'),
	('Pobedy'),
	('Stara-Zagora');

insert into test_serial(id, name) values (333, 'Tomashevskiy tupik');
insert into test_serial(name) values ('Krasnorechenskaya');

select * from test_serial;


8.
drop table test_serial;
create table test_serial (
	id serial,
	name text,
	primary key (id)
);

insert into test_serial (name) values ('Sovietskoy army');
insert into test_serial (name) values ('Pobedy');
insert into test_serial (name) values ('Stara-Zagora');
delete from test_serial where id = 3;
insert into test_serial (name) values ('Tomashevskiy tupik');
insert into test_serial(name) values ('Krasnorechenskaya');

select * from test_serial order by id;


9.


10.


11.
select current_time; -- "17:45:46.619188+04:00"
select current_time::time(0); -- "17:46:08"
select current_time::time(3); -- "17:46:23.854"

select current_timestamp::time; -- "17:47:22.56225"
select current_timestamp::time(0); -- "17:47:43"
select current_timestamp::time(3); -- "17:48:04.23"

select (('15:45:50'::time - '17:35:50.333333333'::time)::interval);
select (('15:45:50'::time - '17:35:50.333333333'::time)::interval)::time(0);
select (('15:45:50'::time - '17:35:50.333333333'::time)::interval)::time(3);\

select ('2024-21-04'::date)::time(0)
-- ERROR:  date/time field value out of range: "2024-21-04"

12.
select current_timestamp; -- "2024-04-21 18:08:33.866187+04"

set datestyle to 'Postgres, DMY';
select current_timestamp; -- "Sun 21 Apr 18:07:45.8743 2024 +04"

set datestyle to 'German, DMY';
select current_timestamp; -- "21.04.2024 18:11:11.875683 +04"

set datestyle to 'SQL, DMY';
select current_timestamp; -- "21/04/2024 18:11:00.516871 +04"

set datestyle to DEFAULT;
select current_timestamp; -- "2024-04-21 18:11:52.151082+04"


13.


14.


15.
select to_char(current_timestamp, 'hh:mi:ss | yyyy-mm-dd'); -- "06:25:43 | 2024-04-21"
select to_char(current_timestamp, 'dd'); -- "21"
select to_char(current_timestamp, 'yyyy-mm-dd'); -- "2024-04-21"


16.
select 'Feb 29, 2019'::date;
-- ERROR:  date/time field value out of range: "Feb 29, 2019"


17.
select '21:21:21.999'::time; -- "21:21:21.999"
select '21:21:21:99999'::time; -- ERROR:  invalid input syntax for type time: "21:21:21:99999"


18.
select ('2024-05-30'::date - '2023-05-30'::date); -- the type will be "integer"
select ('2024-05-30'::date - '2023-05-30'::date)::interval;
ERROR:  cannot cast type integer to interval
select ('2024-05-30'::timestamp - '2023-05-30'::timestamp)::interval; -- the type will be "interval"


19.
select ('19:45:23'::time - '20:41:21'::time) -- "-00:55:58"
select ('19:45:23'::time + '20:41:21'::time);
ERROR:  operator is not unique: time without time zone + time without time zone


20.
select (current_timestamp - '2016-05-30'::timestamp)::interval as new_date; -- "2883 days 18:39:18.369456"
select (current_timestamp + '1 mon'::interval) as new_date; -- "2024-05-21 18:41:23.825613+04"

21.
select ('2023-12-31'::date + '1 day'::interval) as new_date; -- "2024-01-01 00:00:00"
select ('2024-01-31'::date + '1 mon'::interval) as new_date; -- "2024-02-29 00:00:00"
select ('2024-02-29'::date + '1 mon'::interval) as new_date; -- "2024-03-29 00:00:00"


22.
set intervalstyle to 'sql_standard';
SHOW intervalstyle;
select ('2024-12-31 23:59:31.2131'::timestamp - '2023-12-31 14:51:32.717'::timestamp)::interval; -- "366 9:07:58.4961"

set intervalstyle to 'postgres';
SHOW intervalstyle;
select ('2024-12-31 23:59:31.2131'::timestamp - '2023-12-31 14:51:32.717'::timestamp)::interval; -- "366 days 09:07:58.4961"

set intervalstyle to 'postgres_verbose';
SHOW intervalstyle;
select ('2024-12-31 23:59:31.2131'::timestamp - '2023-12-31 14:51:32.717'::timestamp)::interval; -- "@ 366 days 9 hours 7 mins 58.4961 secs"

set intervalstyle to default;
select ('2024-12-31 23:59:31.2131'::timestamp - '2023-12-31 14:51:32.717'::timestamp)::interval; -- "366 days 09:07:58.4961"

23.
select ('2024-05-30'::date - '2024-05-29'::date) -- "1" the type is integer
select ('2024-05-30'::timestamp - '2024-05-29'::timestamp) -- "1 day" the type is interval


24.
select ('20:34:35'::time - 1);
ERROR:  operator does not exist: time without time zone - integer
select ('20:34:35'::time - '00:00:01'::time); -- "20:34:34"
select ('2024-05-30'::date - 1); -- "2024-05-29"


25.
select (date_trunc('microsecond', '2024-05-30 18:56:31.999921442124'::timestamp)); -- 	"2024-05-30 18:56:31.999921"
select (date_trunc('millisecond', '2024-05-30 18:56:31.999921442124'::timestamp)); -- 	"2024-05-30 18:56:31.999"
select (date_trunc('second', '2024-05-30 18:56:31.999921442124'::timestamp)); -- 		"2024-05-30 18:56:31"
select (date_trunc('minute', '2024-05-30 18:56:31.999921442124'::timestamp)); -- 		"2024-05-30 18:56:00"
select (date_trunc('hour', '2024-05-30 18:56:31.999921442124'::timestamp)); -- 			"2024-05-30 18:00:00"
select (date_trunc('day', '2024-05-30 18:56:31.999921442124'::timestamp)); -- 			"2024-05-30 00:00:00"
select (date_trunc('week', '2024-05-30 18:56:31.999921442124'::timestamp)); -- 			"2024-05-27 00:00:00"
select (date_trunc('month', '2024-05-30 18:56:31.999921442124'::timestamp)); -- 		"2024-05-01 00:00:00"
select (date_trunc('year', '2024-05-30 18:56:31.999921442124'::timestamp)); -- 			"2024-01-01 00:00:00"
select (date_trunc('decade', '2024-05-30 18:56:31.999921442124'::timestamp)); -- 		"2020-01-01 00:00:00"
select (date_trunc('century', '2024-05-30 18:56:31.999921442124'::timestamp)); -- 		"2001-01-01 00:00:00"
select (date_trunc('millennium', '2024-05-30 18:56:31.999921442124'::timestamp)); -- 	"2001-01-01 00:00:00"


26.


27
select extract('microsecond' from '2024-05-30 18:56:31.999921442124'::timestamp); -- 31999921
select extract('millisecond' from '2024-05-30 18:56:31.999921442124'::timestamp); -- 31999.921
select extract('second' from '2024-05-30 18:56:31.999921442124'::timestamp); -- 31.999921
select extract('minute' from '2024-05-30 18:56:31.999921442124'::timestamp); -- 56
select extract('hour' from '2024-05-30 18:56:31.999921442124'::timestamp); -- 18
select extract('day' from '2024-05-30 18:56:31.999921442124'::timestamp); -- 30
select extract('week' from '2024-05-30 18:56:31.999921442124'::timestamp); -- 22
select extract('month' from '2024-05-30 18:56:31.999921442124'::timestamp); -- 5
select extract('year' from '2024-05-30 18:56:31.999921442124'::timestamp); -- 2024
select extract('decade' from '2024-05-30 18:56:31.999921442124'::timestamp); -- 202
select extract('century' from '2024-05-30 18:56:31.999921442124'::timestamp); -- 21
select extract('millennium' from '2024-05-30 18:56:31.999921442124'::timestamp); -- 3


28.

29.
select * from databases where NOT is_open_source;
select * from databases where is_open_source;
select * from databases where is_open_source = 'yes';
select * from databases where is_open_source = 't';
select * from databases where is_open_source = '1';
select * from databases where is_open_source = 1;
ERROR:  operator does not exist: boolean = integer


30.
drop table test_bool;
create table test_bool (
	a boolean,
	b text
);

insert into test_bool (a, b) values (true, 'yes');
-- insert into test_bool (a, b) values (yes, 'yes');
-- ERROR:  column "yes" does not exist
insert into test_bool (a, b) values ('yes', true);
insert into test_bool (a, b) values ('yes', TRUE);
insert into test_bool (a, b) values ('1', 'true');
-- insert into test_bool (a, b) values (1, 'true');
-- ERROR:  column "a" is of type boolean but expression is of type integer
insert into test_bool (a, b) values ('t', 'true');
-- insert into test_bool (a, b) values ('t', truth);
-- ERROR:  column "truth" does not exist
insert into test_bool (a, b) values (true, true);
insert into test_bool (a, b) values (1::boolean, 'true');
insert into test_bool (a, b) values (111::boolean, 'true');

select * from test_bool;


31.
drop table birthdays;
create table birthdays (
	person text not null,
	birthday date not null
);

insert into birthdays (person, birthday) values ('Ken Thompson', '1955-03-23');
insert into birthdays (person, birthday) values ('Ben Johnosn', '1971-03-19');
insert into birthdays (person, birthday) values ('Andy Gibson', '1987-08-12');

select * from birthdays where extract('mon' from birthday) = 3;
select * from birthdays where birthday + '40 years'::interval <= current_timestamp;
select * from birthdays where birthday + '40 years'::interval <= current_date;
select *, extract(year from age(current_date, birthday)) as days_live from birthdays;


32.
select array_cat(array[1,2,3], array[4,5,6]); -- {1,2,3,4,5,6}
select array_remove(array[1,2,3], 3); -- {1,2}


33.
drop table pilots;
create table pilots(
	pilot_name text,
	schedule integer[],
	meal text[][]
);

INSERT INTO pilots (pilot_name, schedule, meal)
VALUES
    ('Ivan', '{1, 3, 5, 6, 7}'::integer[],
        '{{"A", "pasta", "coffee"},
        {"cutlet", "poridge", "coffee"},
        {"sausage", "poridge", "coffee"}}'::text[][]),
    ('Petr', '{1, 2, 5, 7}'::integer[],
        '{{"B", "pasta", "coffee"},
        {"C", "poridge", "coffee"},
        {"D", "poridge", "tea"}}'::text[][]),
    ('Pavel', '{2, 5}'::integer[],
        '{{"E", "pasta", "coffee"},
        {"F", "poridge", "coffee"},
        {"G", "poridge", "coffee"}}'::text[][]),
    ('Boris', '{3, 5, 6}'::integer[],
        '{{"I", "pasta", "coffee"},
        {"K", "poridge", "coffee"},
        {"L", "poridge", "tea"}}'::text[][]);

-- select meal[1:3] from pilots;
-- select meal [3:][1:2] from pilots;
update pilots set meal[1][2] = 'juice' where pilot_name = 'Pavel';
select * from pilots where pilot_name = 'Pavel';
-- update pilots set meal[1][:] = array_remove(meal[1][:], 'A') where pilot_name = 'Pavel';
-- ERROR:  removing elements from multidimensional arrays is not supported
update pilots set meal[1][2] = null where pilot_name = 'Pavel';
select * from pilots where pilot_name = 'Pavel';


34.
select * from pilot_hobbies;
-- select * from pilot_hobbies where hobbies -> 'sports' @> '["swimming", "tennis"]'::jsonb;
update pilot_hobbies set hobbies = jsonb_set(hobbies, '{ trips }', '10') where pilot_name = 'Pavel';
update pilot_hobbies set hobbies = jsonb_set(hobbies, '{home_lib}', 'true');
select * from pilot_hobbies where hobbies -> 'sports' @> '["swimming"]'::jsonb and hobbies -> 'trips' = '10' and pilot_name = 'Pavel';

35.
select '{"sports" : ["hockey", "swimming"]}'::jsonb || '{"trips":5}'::jsonb;


36. && 37
drop table json_test;
create table json_test (
	id serial,
	misc jsonb,
	primary key (id)
);

insert into json_test (misc) values ('{"age":20, "hobbies":["programming", "running", "crypto"]}');
update json_test set misc = misc || '{"isSmoking":true}'::jsonb where id = 1;
update json_test set misc = misc - 'isSmoking' where id = 1;
select * from json_test;