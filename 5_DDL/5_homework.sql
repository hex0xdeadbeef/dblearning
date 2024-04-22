1.

alter table students add column who_adds_row text default current_user; -- added column
alter table students add column addition_time timestamp default current_timestamp; -- added column

insert into students values (12345, 'Dmitriy', 3333, 111111);
insert into students (record_book, name, doc_ser, doc_num) values (67890, 'Kate', 2222, 666666);

select * from students;

2.
alter table progress drop constraint progress_term_check;
alter table progress add column test_form text not null check (test_form in ('exam', 'test'));
alter table progress add check ( (test_form = 'exam' and mark in (3,4,5)) or (test_form = 'test' and mark in (0,1) ) );
alter table progress add check ( mark in (2,3,4,5)); -- there are no conflicts
insert into progress (record_book, subject, acad_year, mark, term, test_form) values (12345, 'Math', '2024', 5, 1, 'exam');
insert into progress (record_book, subject, acad_year, mark, term, test_form) values (67890, 'Informatics', '2024', 5, 1, 'test');
ERROR:  Failing row contains (67890, Informatics, 2024, 5, 1, test).new row for relation "progress" violates check constraint "progress_check"
insert into progress (record_book, subject, acad_year, mark, term, test_form) values (67890, 'Informatics', '2024', 5, 1, 'exam');
select * from progress;


3.
alter table progress add check (term in (1,2));
alter table progress alter column term drop not null;
alter table progress alter column mark drop not null;
insert into progress (record_book, subject, acad_year, mark, term, test_form) values (12345, 'English', '2024', null, null, 'exam');
the check "not null" is relevant despite others ones:
    "progress_mark_check" CHECK (mark = ANY (ARRAY[2::numeric, 3::numeric, 4::numeric, 5::numeric]))
    "progress_term_check" CHECK (term = ANY (ARRAY[1::numeric, 2::numeric]))
select * from progress;
alter table progress alter column term set not null;
alter table progress alter column mark set not null;


4.
alter table progress alter column mark set default 6;
insert into progress (record_book, subject, acad_year, term, test_form) values (12345, 'English', '2024', 2, 'exam');
ERROR:  Failing row contains (12345, English, 2024, 6, 2, exam).new row for relation "progress" violates check constraint "mark_check"
alter table progress alter column mark set default 5;


5.
alter table students add unique(doc_ser, doc_num);
insert into students (record_book, name, doc_ser, doc_num) values (33333, 'Denis', null, null), (33334, 'Denis', null, null);
insert into students (record_book, name, doc_ser, doc_num) values (33335, 'Rustam', null, null), (33336, 'Rustam', null, null);
select * from students;
select (null = null); -- [null]

6.
alter table progress drop constraint progress_record_book_fkey;
alter table students drop constraint students_pkey;
alter table students add constraint multi_pk primary key (doc_ser, doc_num);
alter table progress add column doc_ser numeric(4);
alter table progress add column doc_num numeric(6);
select * from progress;
update progress set doc_ser = 3333, doc_num = 111111 where record_book = 12345;
update progress set doc_ser = 2222, doc_num = 666666 where record_book = 67890;
alter table progress add constraint new_fk foreign key (doc_ser, doc_num) references students (doc_ser, doc_num) on delete cascade on update cascade;
insert into students (record_book, name, doc_ser, doc_num) values (33333, 'Denis', 3333, 333333);
insert into progress values (99999, 'Native Language', 2024, 4, 2, 'exam', 3333, 333333);
update students set doc_ser = 7777 where doc_ser = 3333;
select * from progress;
