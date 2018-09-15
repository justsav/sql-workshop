-- Create a database.
-- $ createdb phone_book
--
-- Import the sample data.
-- $ psql -f data/contacts.sql phone_book
--
-- Start the psql PostgreSQL client
-- $ psql phone_book

-- The basic select statement:
select name, phone from contacts;

-- * is the shortcut for selecting all columns:
select * from contacts;

-- Rows are filtered with a `where` clause.

select name
from contacts
where phone='579-804-9800';

-- Exercise 1:
--   1.1 Find phone number for Lauri Abshire.
--   1.2 Find who has the phone number 363-350-4983.

-- Now what happens if we only know someone's first name? The `%` is the
-- wildcard character for a LIKE pattern. It matches any number of any character.
select name, phone
from contacts
where name like 'Tammi%';

-- Exercise 2:
--   2.1 Find phone number for the last name of Hermann.

-- ILIKE is used to search case-insensitively.

select name, phone
from contacts
where name ilike '%dare';

-- The INSERT statement is used to insert rows into a table.
insert into contacts(name, phone) values ('John Smith', '432-422-4945');

-- Try to insert a record without a phone number.
insert into contacts(name) values ('John Locke');

-- Inspect the table definition
\d contacts

-- One of the meanings of NULL is "empty". The columns in the contacts table are constrained to be NOT NULL.

-- To update a contact we use the update statement.
update contacts
set phone='817-348-5998'
where name='Simonne Bayer';

-- Exercise 3:
--   3.1 Change John Smith's phone number to 212-987-2342

-- Lastly, let's delete a record.
delete from contacts where name='Kaylene Bahringer';

-- Notice that SELECT, UPDATE, and DELETE all allow a WHERE clause. It is very
-- important to include a WHERE clause on UPDATE and DELETE statements.

-- The result of a SELECT can be ordered with the ORDER BY clause.
select *
from contacts
order by name;

-- The order can be reversed with DESC (the default is ASC).
select *
from contacts
order by name desc;

-- We can limit the number of rows returned with the LIMIT key word.
select *
from contacts
order by name
limit 5;

-- We are starting to run into a problem with how to tell rows apart. People can
-- share names. They can also share phone numbers. We need some way uniquely
-- identify rows. A unique identifier is called a key. The most important unique
-- identifier is called the primary key. With very few exceptions every table
-- should have a primary key.
alter table contacts
add column id int generated by default as identity,
add primary key (id);

-- Now that we have contacts let's keep track of calls.
create table calls(
  id int primary key generated by default as identity,
  contact_id integer not null,
  call_start timestamptz not null,
  call_duration interval not null
);

-- Discussion:
--   What is a time?
--   Do times include time zones?
--   Do dates include time zones?
--   Can time go backwards?
--   Do all dates and times exist?

-- Insert a call record.
insert into calls(contact_id, call_start, call_duration)
values (1, '2018-04-13 18:12:50', '3 minutes 23 seconds');

-- It is useful to know what the auto-assigned primary key was.
insert into calls(contact_id, call_start, call_duration)
values (2, '2018-08-04 09:12:45', '7 minutes 2 seconds')
returning id;

-- We can insert multiple rows in a single statement.
insert into calls(contact_id, call_start, call_duration)
values
  (2, '2018-08-07 19:01:32', '5 minutes 52 seconds'),
  (2, '2018-08-09 22:12:45', '39 minutes 32 seconds')
returning id;

-- What happens if we insert a record for a non-existent contact?
insert into calls(contact_id, call_start, call_duration)
values (99999, '2018-05-23 17:09:49', '1 hour')
returning id;

-- Yuck. Delete that record please (replace LAST_ID with the actual id).
delete from calls where id=LAST_ID;

-- PostgreSQL can protect us with foreign key constraints.
alter table calls
add foreign key (contact_id) references calls(id);

-- Try insert again.
insert into calls(contact_id, call_duration)
values (99999, '1 hour')
returning id;

-- (Almost) always use foreign key constraints.

-- How do we make these two tables work together?

-- The simplest join is CROSS JOIN.
select *
from contacts
  cross join calls;

-- Usually, we want a (INNER) JOIN.
select *
from contacts
  join calls on contacts.id=calls.contact_id;

-- Aggregate functions reduce multiple rows into one.
select count(*) from calls;
select sum(call_duration) from calls;
select avg(call_duration) from calls;

-- GROUP BY is used to group rows for aggregate functions.
select contact_id, count(*) from calls group by contact_id;
select contact_id, sum(call_duration) from calls group by contact_id;
select contact_id, avg(call_duration) from calls group by contact_id;

-- All selected columns must be either included in group by or an aggregate function.
select contact_id, call_start, count(*) from calls group by contact_id;

-- Discussion: Why doesn't the above work?

-- Multiple aggregate functions can be called in a single query.
select contact_id, count(*), sum(call_duration), avg(call_duration)
from calls
group by contact_id;

-- Joins can be combined with aggregate functions.
select contacts.id, contacts.name, count(*), sum(call_duration), avg(call_duration)
from contacts
  join calls on contacts.id=calls.contact_id
group by contacts.id, contacts.name;

-- What if we want to include contacts who had no calls?
select contacts.id, contacts.name, count(*), sum(call_duration), avg(call_duration)
from contacts
  left join calls on contacts.id=calls.contact_id
group by contacts.id, contacts.name;

-- Discussion: What is NULL?

-- The COALESCE function can convert nulls to some other value.
select contacts.id, contacts.name,
  coalesce(count(*), 0),
  coalesce(sum(call_duration), '00:00:00'),
  coalesce(avg(call_duration), '00:00:00')
from contacts
  left join calls on contacts.id=calls.contact_id
group by contacts.id, contacts.name;
