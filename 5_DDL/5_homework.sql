-- 1.

-- alter table students add column who_adds_row text default current_user; -- added column
-- alter table students add column addition_time timestamp default current_timestamp; -- added column

-- insert into students values (12345, 'Dmitriy', 3333, 111111);
-- insert into students (record_book, name, doc_ser, doc_num) values (67890, 'Kate', 2222, 666666);

-- select * from students;

-- 2.
-- alter table progress drop constraint progress_term_check;
-- alter table progress add column test_form text not null check (test_form in ('exam', 'test'));
-- alter table progress add check ( (test_form = 'exam' and mark in (3,4,5)) or (test_form = 'test' and mark in (0,1) ) );
-- alter table progress add check ( mark in (2,3,4,5)); -- there are no conflicts
-- insert into progress (record_book, subject, acad_year, mark, term, test_form) values (12345, 'Math', '2024', 5, 1, 'exam');
-- insert into progress (record_book, subject, acad_year, mark, term, test_form) values (67890, 'Informatics', '2024', 5, 1, 'test');
-- ERROR:  Failing row contains (67890, Informatics, 2024, 5, 1, test).new row for relation "progress" violates check constraint "progress_check"
-- insert into progress (record_book, subject, acad_year, mark, term, test_form) values (67890, 'Informatics', '2024', 5, 1, 'exam');
-- select * from progress;


-- 3.
-- alter table progress add check (term in (1,2));
-- alter table progress alter column term drop not null;
-- alter table progress alter column mark drop not null;
-- insert into progress (record_book, subject, acad_year, mark, term, test_form) values (12345, 'English', '2024', null, null, 'exam');
-- the check "not null" is relevant despite others ones:
--     "progress_mark_check" CHECK (mark = ANY (ARRAY[2::numeric, 3::numeric, 4::numeric, 5::numeric]))
--     "progress_term_check" CHECK (term = ANY (ARRAY[1::numeric, 2::numeric]))
-- select * from progress;
-- alter table progress alter column term set not null;
-- alter table progress alter column mark set not null;


-- 4.
-- alter table progress alter column mark set default 6;
-- insert into progress (record_book, subject, acad_year, term, test_form) values (12345, 'English', '2024', 2, 'exam');
-- ERROR:  Failing row contains (12345, English, 2024, 6, 2, exam).new row for relation "progress" violates check constraint "mark_check"
-- alter table progress alter column mark set default 5;


-- 5.
-- alter table students add unique(doc_ser, doc_num);
-- insert into students (record_book, name, doc_ser, doc_num) values (33333, 'Denis', null, null), (33334, 'Denis', null, null);
-- insert into students (record_book, name, doc_ser, doc_num) values (33335, 'Rustam', null, null), (33336, 'Rustam', null, null);
-- select * from students;
-- select (null = null); -- [null]

-- 6.
-- alter table progress drop constraint progress_record_book_fkey;
-- alter table students drop constraint students_pkey;
-- alter table students add constraint multi_pk primary key (doc_ser, doc_num);
-- alter table progress add column doc_ser numeric(4);
-- alter table progress add column doc_num numeric(6);
-- select * from progress;
-- update progress set doc_ser = 3333, doc_num = 111111 where record_book = 12345;
-- update progress set doc_ser = 2222, doc_num = 666666 where record_book = 67890;
-- alter table progress add constraint new_fk foreign key (doc_ser, doc_num) references students (doc_ser, doc_num) on delete cascade on update cascade;
-- insert into students (record_book, name, doc_ser, doc_num) values (33333, 'Denis', 3333, 333333);
-- insert into progress values (99999, 'Native Language', 2024, 4, 2, 'exam', 3333, 333333);
-- update students set doc_ser = 7777 where doc_ser = 3333;
-- select * from progress;
 

-- 7.
-- select * from students;
-- alter table progress drop constraint new_fk;
-- alter table progress add constraint new_fk  FOREIGN KEY (doc_ser, doc_num) REFERENCES students(doc_ser, doc_num) ON UPDATE RESTRICT ON DELETE RESTRICT;
-- delete from students where record_book = 67890;
-- ERROR:  update or delete on table "students" violates foreign key constraint "progress_doc_ser_doc_num_fkey" on table "progress"

-- alter table progress drop constraint new_fk;
-- alter table progress add constraint new_fk  FOREIGN KEY (doc_ser, doc_num) REFERENCES students(doc_ser, doc_num) ON UPDATE SET NULL ON DELETE SET NULL;
-- delete from students where record_book = 67890;
-- select * from progress
-- 67890	"Informatics"	"2024"	5	1	"exam"		 -- doc_ser and doc_num has been set to null values
-- insert into students (record_book, name, doc_ser, doc_num) values (67890, 'Kate', 2222, 666666);
-- update progress set doc_ser = 2222, doc_num = 666666 where record_book = 67890;

-- alter table progress drop constraint new_fk;
-- alter table progress
-- 	alter column doc_ser set default 0,
-- 	alter column doc_num set default 0;
-- insert into students (record_book, name, doc_ser, doc_num) values (67890, 'Kate', 2222, 666666);
-- alter table progress add constraint new_fk foreign key (doc_ser, doc_num) references students (doc_ser, doc_num) on delete set default on update set default;
-- insert into students (record_book, name, doc_ser, doc_num) values (67890, 'Drags', 0, 0);
-- update students set doc_ser = 1111, doc_num = 111111 where record_book = 67891;
-- select * from students;

-- alter table progress drop constraint new_fk;
-- alter table progress add constraint new_fk  FOREIGN KEY (doc_ser, doc_num) REFERENCES students(doc_ser, doc_num) ON UPDATE CASCADE ON DELETE CASCADE;
-- update progress set doc_ser = 1111, doc_num = 111111 where doc_ser = 0 and doc_num = 0;
-- delete from students where doc_ser = 0 and doc_num = 0;


-- 8.
-- create table subjects (
-- 	id serial,
-- 	subject text not null,

-- 	unique(subject),
-- 	primary key (id)
-- )

-- insert into subjects (subject) values ('Math'), ('Native Language'), ('Informatics');

-- alter table progress alter column subject set data type integer
-- using (
-- 	case when subject = 'Math' then 1
-- 	when subject = 'Native Language' then 2
-- 	when subject = 'Informatics' then 3
-- 	end);

-- alter table progress add constraint valid_subject_id foreign key (subject) references subjects (id);
-- insert into progress values (67890, 2, 2024, 3, 2, 'exam', 1111, 111111);
-- insert into progress values (67890, 4, 2024, 3, 2, 'exam', 1111, 111111);
-- ERROR:  Key (subject)=(4) is not present in table "subjects".insert or update on table "progress" violates foreign key constraint "valid_subject_id"


-- 9.
-- insert into students (record_book, name, doc_ser, doc_num) values (54321, '', 2222, 222222);
-- alter table students add check (name <> '');
-- insert into students (record_book, name, doc_ser, doc_num) values (54321, '', 2222, 222222);
-- ERROR:  Failing row contains (54321, , 2222, 222222, postgres, 2024-04-23 14:20:24.53686).new row for relation "students" violates check constraint "students_name_check" 
-- insert into students (record_book, name, doc_ser, doc_num) values (54321, 'Arkadiy', 2222, 222222);
-- insert into students (record_book, name, doc_ser, doc_num) values (57771, '   ', 2112, 221122);
-- delete from students where record_book = 57771;
-- alter table students add check (trim(name) <> '');
-- insert into students (record_book, name, doc_ser, doc_num) values (57771, '   ', 2112, 221122);
-- ERROR:  Failing row contains (57771,    , 2112, 221122, postgres, 2024-04-23 14:23:50.457842).new row for relation "students" violates check constraint "students_name_check1" 

-- alter table progress add check (trim (acad_year) <> '');


-- 10.
-- alter table progress drop constraint new_fk;
-- alter table progress alter column doc_ser set data type varchar(4);
-- alter table students alter column doc_ser set data type varchar(4);
-- alter table progress add constraint new_fk FOREIGN KEY (doc_ser, doc_num) REFERENCES students(doc_ser, doc_num) ON UPDATE CASCADE ON DELETE CASCADE;
-- select * from students;
-- select * from progress;


-- 11. 


-- 12.


-- 13.


-- 14.
-- insert into progress (record_book, subject, acad_year, mark, term, test_form, doc_ser, doc_num) values (67890, 5, '2024', 4, 1, 'exam', 1111, 111111);
-- insert into progress (record_book, subject, acad_year, mark, term, test_form, doc_ser, doc_num) values (67890, 5, '2024', 3, 1, 'exam', 1111, 111111);
-- insert into progress (record_book, subject, acad_year, mark, term, test_form, doc_ser, doc_num) values (12345, 2, '2024', 3, 1, 'exam', 7777, 111111);
-- drop view get_bad_students_record_books;
-- create view get_bad_students_record_books as select record_book, mark from progress where mark = 3;
-- update get_bad_students_record_books set mark = 4;

-- create view get_good_marks_students as select record_book, mark from progress where mark = 4;
-- delete from get_good_marks_students; 
-- select * from progress;
-- insert into progress (record_book, subject, acad_year, mark, term, test_form, doc_ser, doc_num) values (67890, 5, '2024', 4, 1, 'exam', 1111, 111111);
-- insert into progress (record_book, subject, acad_year, mark, term, test_form, doc_ser, doc_num) values (67890, 5, '2024', 3, 1, 'exam', 1111, 111111);
-- insert into progress (record_book, subject, acad_year, mark, term, test_form, doc_ser, doc_num) values (12345, 2, '2024', 3, 1, 'exam', 7777, 111111);
-- select * from progress;

-- drop view great_students;
-- create view great_students as select * from progress where mark = 5;
-- insert into great_students (record_book, subject, acad_year, mark, term, test_form, doc_ser, doc_num) values (12345, 5, '2024', 5, 2, 'exam', 7777, 111111);


-- 15.


-- 16.
-- create materialized view good_marks_students as select record_book, doc_ser, doc_num from progress where mark = 5;
-- select * from good_marks_students;
-- insert into students (record_book, name, doc_ser, doc_num) values (77777, 'Rustam', 4444, 444444);
-- insert into progress (record_book, subject, acad_year, mark, term, test_form, doc_ser, doc_num) values (77777, 4, '2024', 5, 1, 'exam', 4444, 444444);
-- select * from good_marks_students; -- old data without latter addition
-- refresh materialized view good_marks_students;
-- select * from good_marks_students; -- new data presented


-- 17.
-- create view vertical_progress_view as select record_book, doc_ser, doc_num from progress;
-- create view horizontal_progress_view as select * from progress where mark = 5;
-- create view mixed_view_progress as select record_book, mark, doc_ser, doc_num from progress where mark >= 4 group by record_book, mark, doc_ser, doc_num;
-- select * from mixed_view_progress order by mark desc; 


-- -- 18.
-- -- alter table aircrafts_data add column specifications jsonb;
-- -- update aircrafts_data set specifications = '{"crew_num":2, "engines": {"type":"IAE V2500", "count":2}}'::jsonb where aircraft_code = '320';
-- select * from aircrafts_data where aircraft_code = '320';
-- -- "320"	"{""en"": ""Airbus A320-200"", ""ru"": ""Аэробус A320-200""}"	5700	"{""engines"": {""type"": ""IAE V2500"", ""count"": 2}, ""crew_num"": 2}"
-- select specifications -> 'engines' from aircrafts_data where aircraft_code = '320';
-- -- "{""type"": ""IAE V2500"", ""count"": 2}"

-- select specifications -> 'engines' #> '{type}' from aircrafts_data where aircraft_code = '320';
-- -- """IAE V2500"""
-- -- OR
-- select specifications #> '{engines, type}' from aircrafts_data where aircraft_code = '320';
-- -- """IAE V2500"""