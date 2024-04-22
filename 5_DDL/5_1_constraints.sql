
create table students (
	record_book numeric(5) not null, -- primary key,

	name text not null,

	doc_ser numeric(4),
	doc_num numeric(6),

	primary key (record_book)
	-- primary key (doc_ser, doc_num),
	-- constraint unique_record_book unique (record_book)
	-- constraint unique_passport unique(doc_ser, doc_num),
);

create table progress (
	record_book numeric(5) not null, -- references students (record_book) -- because record_book is the primary key we could write "references students"
	subject text not null,
	acad_year text not null,

	mark numeric(1) not null default 5 ,
	term numeric(1) not null check (term = 1 or term = 2),

	constraint valid_mark check (mark >= 3 and mark <= 5),

	foreign key (record_book) references students (record_book) on delete cascade on update cascade
	-- 0. the default value is established "no action"
	-- 1. "on delete cascade" | "on update cascade"
	-- 2. "on delete restrict" or "on delete action" when we restrict the deletion from students if there's a row in the progress referencing to the corresponding record_book in the students table.
	-- In the case of "on delete action" we can postpone the check for a while within a tx.
	-- 3. "on delete set null" to set the null value after the deletion the corresponding row in the students table. So that we can do it, the attr must not have the
	-- constraint "not null"
	-- 4. "on delete set default" to set the default value for an attribute after the deletion from the students table. So that we can do it the attr must have the
	-- default value set for referencing table and referenced table as well.
);