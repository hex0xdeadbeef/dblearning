-- 9.1
-- show default_transaction_isolation;
-- "read committed"


----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- drop table if exists aircrafts_tmp;
-- create table if not exists aircrafts_tmp as select * from aircrafts;
----------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 9.2 DIRTY READ Read UNCOMMITTED/COMMITTED isolation levels (excludes "lost update", "dirty read")
-- DIRTY READ is: there a tx A and tx B. B has changed the data and hasn't commited iDIRTY READt. The tx A reads the changed data. If the tx B will be canceled, the tx A
-- will remain with the "dirty" data.

-- TERMINAL 1
-- begin;
-- BEGIN
-- set transaction isolation level read uncommitted / committed;
-- SET
-- update aircrafts_tmp set range = range + 100 where aircraft_code = 'SU9';
-- UPDATE 1
-- commit;
-- COMMIT

-- TERMINAL 2
-- begin;
-- BEGIN
-- set transaction isolation level read uncommitted / committed;
-- SET
-- BEFORE COMMIT
-- select * from aircrafts_tmp where aircraft_code = 'SU9';
-- "SU9"	"Сухой Суперджет-100"	3000
-- AFTER COMMIT
-- select * from aircrafts_tmp where aircraft_code = 'SU9';
-- "SU9"	"Сухой Суперджет-100"	3100
-- commit;


-- 9.3 LOST UPDATES Read COMMITTED/UNCOMMITTED isolation levels (excludes "lost update", "dirty read") 

-- LOST UPDATES is: tx A changes the value and the tx B changes the value. Finally it's possible for either transaction to rewrite the data. One of the writes
-- will be lost.

-- TERMINAL 1
-- begin isolation level read committed;
-- BEGIN
-- update aircrafts_tmp set range = range + 100 where aircraft_code = 'SU9';
-- UPDATE 1
-- commit;
-- select * from aircrafts_tmp where aircraft_code = 'SU9';
-- "SU9"	"Сухой Суперджет-100"	3100
-- commit;

-- TERMINAL 2
-- begin isolation level read committed;
-- BEGIN
-- update aircrafts_tmp set range = range + 200 where aircraft_code = 'SU9';
-- -- After this query the terminal will be waiting for the ending the first tx. After this waiting the value will be correspondingly changed based on the update
-- of the first tx.
-- select * from aircrafts_tmp where aircraft_code = 'SU9';
-- "SU9"	"Сухой Суперджет-100"	3300
-- end;
-- COMMIT

-- NON-REPEATABLE READ is: tx A reads the rows from the table getting the data, tx B changes the data and commits, tx A reads the data again and gets updated data.

-- TERMINAL 1
-- begin;
-- select * from aircrafts_tmp order by model;
-- "733"	"Боинг 737-300"	4200
-- "763"	"Боинг 767-300"	7900
-- "773"	"Боинг 777-300"	11100
-- "SU9"	"Сухой Суперджет-100"	3000
-- "CN1"	"Сессна 208 Караван"	1200
-- "319"	"Аэробус A319-100"	6700
-- "320"	"Аэробус A320-200"	5700
-- "321"	"Аэробус A321-200"	5600
-- "CR2"	"Бомбардье CRJ-200"	2700
-- select * from aircrafts_tmp order by model;
-- "SU9"	"Сухой Суперджет-100"	3000
-- "CN1"	"Сессна 208 Караван"	1200
-- "319"	"Аэробус A319-100"	6700
-- "320"	"Аэробус A320-200"	5700
-- "321"	"Аэробус A321-200"	5600
-- "CR2"	"Бомбардье CRJ-200"	2700
-- end;
-- COMMIT

-- TERMINAL 2
-- begin;
-- delete from aircrafts_tmp where model like 'Боинг%';
-- DELETE 3
-- end;
-- COMMIT


-- 9.4 REPEATABLE READ Repeatable Read isolation level
-- NON-REPEATABLE READ is: tx A reads the rows from the table getting the data, tx B changes the data and commits, tx A reads the data again and gets updated data.

-- TERMINAL 1
-- begin isolation level repeatable read;
-- The tx with the repeatable read isolation level makes the snapshot only before the first query
-- select * from aircrafts_tmp order by model;
-- "733"	"Боинг 737-300"	4200
-- "763"	"Боинг 767-300"	7900
-- "773"	"Боинг 777-300"	11100
-- "SU9"	"Сухой Суперджет-100"	3000
-- "CN1"	"Сессна 208 Караван"	1200
-- "319"	"Аэробус A319-100"	6700
-- "320"	"Аэробус A320-200"	5700
-- "321"	"Аэробус A321-200"	5600
-- "CR2"	"Бомбардье CRJ-200"	2700
-- select * from aircrafts_tmp order by model;
-- "733"	"Боинг 737-300"	4200
-- "763"	"Боинг 767-300"	7900
-- "773"	"Боинг 777-300"	11100
-- "SU9"	"Сухой Суперджет-100"	3000
-- "CN1"	"Сессна 208 Караван"	1200
-- "319"	"Аэробус A319-100"	6700
-- "320"	"Аэробус A320-200"	5700
-- "321"	"Аэробус A321-200"	5600
-- "CR2"	"Бомбардье CRJ-200"	2700
-- end;
-- select * from aircrafts_tmp order by model;
-- "IL9"	"Ilyushin IL96"	9800 -- The new row
-- "733"	"Боинг 737-300"	4200
-- "763"	"Боинг 767-300"	7900
-- "773"	"Боинг 777-300"	11100
-- "SU9"	"Сухой Суперджет-100"	3100 -- The updated value
-- "CN1"	"Сессна 208 Караван"	1200
-- "319"	"Аэробус A319-100"	6700
-- "320"	"Аэробус A320-200"	5700
-- "321"	"Аэробус A321-200"	5600
-- "CR2"	"Бомбардье CRJ-200"	2700

-- TERMINAL 2
-- begin isolation level repeatable read;
-- The tx with the repeatable read isolation level makes the snapshot only before the first query
-- insert into aircrafts_tmp values ('IL9', 'Ilyushin IL96', 9800);
-- INSERT 0 1
-- update aircrafts_tmp set range = range + 100 where aircraft_code = 'SU9';
-- UPDATE 1
-- end;
-- COMMIT


-- PHANTOMS

-- TERMINAL 1
-- begin isolation level repeatable read;
-- BEGIN
-- update aircrafts_tmp set range = range + 100 where aircraft_code = '320';
-- UPDATE 1
-- end;
-- COMMIT
-- select * from aircrafts_tmp where aircraft_code = '320'; 
-- "320"	"Аэробус A320-200"	5800

-- TERMINAL 2
-- begin isolation level repeatable read;
-- BEGIN
-- update aircrafts_tmp set range = range + 200 where aircraft_code = '320';
-- The op will be waiting for the ending of the first tx;
-- ERROR:  could not serialize access due to concurrent update 
-- end;
-- ROLLBACK


-- 9.5 SERIALIZATION Serializable
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- drop table if exists modes;
-- create table if not exists modes (
-- 	num integer,
-- 	mode text
-- );

-- insert into modes values (1, 'LOW'), (2, 'HIGH');
----------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TERMINAL 1
-- begin isolation level serializable;
-- BEGIN
-- update modes set mode = 'HIGH'
-- where mode = 'LOW'
-- returning *;
-- 1	"HIGH"
-- select * from modes;
-- 2	"HIGH"
-- 1	"HIGH"
-- end;

-- TERMINAL 2
-- begin isolation level serializable;
-- BEGIN
-- update modes set mode = 'LOW'
-- where mode = 'HIGH'
-- returning *;
-- 2	"LOW"
-- select * from modes;
-- end;
-- ERROR:  Reason code: Canceled on identification as a pivot, during commit attempt.could not serialize access due to read/write dependencies among transactions 


-- 9.6 The example of using Transactions.
-- begin;
-- BEGIN

-- insert into bookings (book_ref, book_date, total_amount) values ('ABC123', bookings.now(), 0);
-- INSERT 0 1

-- insert into tickets (ticket_no, book_ref, passenger_id, passenger_name)
-- 	values
-- 		(9991234567890, 'ABC123', '1234 123456', 'IVAN PETROV'),
-- 		(9991234567891, 'ABC123', '4321 654321', 'PETR IVANOV');
-- INSERT 0 2

-- insert into ticket_flights (ticket_no, flight_id, fare_conditions, amount) values 
-- 	(9991234567890, 5572, 'Business', 12500),
-- 	(9991234567890, 13881, 'Economy', 8500);
-- INSERT 0 2

-- insert into ticket_flights (ticket_no, flight_id, fare_conditions, amount) values 
-- 	(9991234567891, 5572, 'Business', 12500),
-- 	(9991234567891, 13881, 'Economy', 8500);
-- INSERT 0 2

-- update bookings set total_amount = (
-- 	select sum(amount)
-- 	from ticket_flights
-- 	where ticket_no in 
-- 		(select ticket_no from tickets where book_ref = 'ABC123')
-- 	)
-- 	where book_ref = 'ABC123';
-- UPDATE 1

-- select * from bookings where book_ref = 'ABC123';
-- "ABC123"	"2017-08-15 19:00:00+04"	42000.00

-- end;
-- COMMIT

-- 9.7 Blocks
-- The command "select" has an addition "FOR UPDATE", that allows a tx to block the specific rows in a table in order to update them. If a tx blocks the rows,
-- the other parallel txs won't be able to block them until the first one ends and the block will be free correspondingly.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- drop table if exists aircrafts_tmp;
-- create table aircrafts_tmp as select * from aircrafts;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- ROWS BLOCKING
-- TERMINAL 1
-- begin transaction isolation level read committed;
-- BEGIN
-- select * from aircrafts_tmp where model like 'Аэр%' for update;
-- "321"	"Аэробус A321-200"	5600
-- "319"	"Аэробус A319-100"	6700
-- "320"	"Аэробус A320-200"	5700
-- update aircrafts_tmp set range = 10000 where aircraft_code = '321';
-- end;

-- TERMINAL 2
-- begin transaction isolation level read committed;
-- select * from aircrafts_tmp where model like 'Аэр%' for update;
-- This query will be waiting for the ending of the first query until it ends its work;
-- "321"	"Аэробус A321-200"	10000
-- "319"	"Аэробус A319-100"	6700
-- "320"	"Аэробус A320-200"	5700
-- end;
-- COMMIT

-- TABLES BLOCKING
-- TERMINAL 1
-- begin transaction isolation level read committed;
-- BEGIN
-- lock table aircrafts_tmp in access exclusive mode;
-- LOCK TABLE
-- end;
-- COMMIT

-- TERMINAL 2
-- begin transaction isolation level read committed;
-- BEGIN
-- select * from aircrafts_tmp where model like 'Аэр%';
-- This query will be waiting for the first query to end its work.
-- "319"	"Аэробус A319-100"	6700
-- "320"	"Аэробус A320-200"	5700
-- "321"	"Аэробус A321-200"	10000