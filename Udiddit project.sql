-- Part II --

-- 1a.--

create table "users" (
    "id" serial Primary Key,
    "username" varchar(25) unique not null check (length(trim("username")) > 0),
    "time_login" timestamp
);
create index "users_find" on "users" ("username");

-- 1b. --

create table "topics" (
    "id" serial primary key,
    "topic_name" varchar(30) unique not null check (length(trim("topic_name")) > 0),
    "description" varchar(500),
    "time_created" timestamp
);
create index "topic_find" on "topics"("topic_name");

-- 1c --

create table "posts" (
    "id" serial primary key,
    "title" varchar (100) check (length(trim("title")) > 0),
    "content" varchar,
    "url" varchar,
    "topic_id" integer references "topics"("id") on delete cascade,
    "user_id" integer references "users" ("id") on delete set null,
    "time_post" timestamp
);
alter table "posts" add constraint "url_or_content" 
check ((("url")is null and ("content") is not null) or
      (("content")is null and ("url") is not null));

create index "post_find" on "posts"("title");
    
-- 1d --

create table "comments" (
    "id" serial primary key,
    "comment" varchar check (length(trim("comment")) > 0),
    "thread_level" integer references "comments" on delete cascade,
    "post_id" integer not null references "posts"("id") on delete cascade,
    "user_id" integer references "users" ("id") on delete set null,
    "time_comment" timestamp
);

-- 1e --

create table "votes" (
    "id" serial primary key,
    "vote" smallint check ("vote" = 1 or "vote" = -1),
    "user_id" integer references "users" ("id") on delete set null,
    "post_id" integer not null references "posts"("id") on delete cascade,
    "time_voted" timestamp,
    unique ("user_id","post_id")
);
create index "vote_find" on "votes"("post_id");

-- 2a --
create index "login_time" on "users"("time_login");

-- 2b --
create index "post_by_user" on "posts" ("user_id","id");

-- 2c: at 1a already created an index for username --

-- 2d --
create index "post_topic" on "posts" ("topic_id","id");

-- 2e: at 1b already created an index for topic_name --

-- 2f --
create index "post_time" on "posts" ("topic_id","time_post");

-- 2g --
create index "post_user" on "posts" ("user_id");

-- 2h --
create index "post_url" on "posts"("url" varchar_pattern_ops);

-- 2i --
create index "level" on "comments" ("thread_level");

-- 2j --
create index "parent_comment" on "comments" ("id");

-- 2k --
create index "comment_by_user" on "comments" ("user_id", "time_comment");

-- 2l --
create index "vote_score" on "votes" ("vote");

-- 3 --
-- The schema is already normalized with constraints and indexes --

-- 4 --
-- table 1 "users"; table 2 "topics"; table 3 "posts"; table 4 "comments"; table 5 "votes", with the auto-incrementing id as their primary key. --

-- Part III ---
-- Users table --
insert into "users" ("username")
    select distinct username
    from bad_comments;
    
insert into "users" ("username")
    select distinct bp.username
    from bad_posts bp
    left join users u
    on u.username = bp.username
    where u.username is null 
    ;
    
insert into "users" ("username")
select distinct sub.up_username
from (
select regexp_split_to_table(upvotes, ',') up_username
from bad_posts) sub
left join users u
on u.username = sub.up_username
where u.username is null;

insert into "users" ("username")
select sub1.down_username
from (
select regexp_split_to_table(downvotes, ',') down_username
from bad_posts) sub1
left join users u
on u.username = sub1.down_username
where u.username is null;

-- Topic table --
-- Topic descriptions can all be empty --
insert into "topics" ("topic_name")
select distinct topic
from bad_posts;

-- Posts table --

insert into "posts" ("id","title","content","url","topic_id","user_id")
select bp.id, left(bp.title,100), bp.text_content, bp.url, t.id, u.id
from bad_posts bp
join topics t
on t.topic_name = bp.topic
join users u
on u.username = bp.username;

-- Comments table --

insert into "comments" ("id", "comment", "post_id", "user_id")
select bc.id, bc.text_content, p.id, u.id
from bad_comments bc
join users u 
on u.username = bc.username
join posts p
on p.id = bc.post_id;

-- all comments as top-level comments --
update comments set thread_level = 1;

-- Votes table --
insert into "votes" ("vote","user_id","post_id")
select -1 as vote, u.id, sub.id 
from (
select id,regexp_split_to_table(upvotes, ',') up_username
from bad_posts) sub
join users u
on sub.up_username = u.username;

insert into "votes" ("vote","user_id","post_id")
select 1 as vote, u.id, sub1.id 
from (
select id,regexp_split_to_table(downvotes, ',') down_username
from bad_posts) sub1
join users u
on sub1.down_username = u.username;






