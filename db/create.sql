create table users (
    id integer primary key not null
  ,	name varchar(16) not null
  -- , email varchar(128)
);

create table images (
    id integer primary key not null
  , owner integer not null references users.id
  , filename varchar(128) not null
  , external_filename varchar(128) not null
  , width integer not null
  , height integer not null
  , uploaded timestamp not null

  , deleted_on timestamp
  , hidden_on timestamp
  , created_on timestamp default now()
);

create table tags (
    id integer primary key not null
  , is_internal boolean default false
  , name varchar(64) not null
);

create table image_tags (
    image_id integer references images(id)
  , tag_id integer references tags(id)
);

-- Add some users
insert into users (id,name) values (1,'Corion');
insert into users (id,name) values (2,'SomeoneElse');

-- all images must live in the magic "_all" category
-- I should set up a nice trigger to maintain that, instead of doing manual
-- insertion here...
insert into tags (id,is_internal,name) values (0, true, '_all');
insert into tags (id,is_internal,name) values (1, false, 'kittens');

insert into images (id,owner,filename) values (1,1,'mypic1.jpg');
insert into images_tags (image_id,tag_id) values (1,0);
insert into images (id,owner,filename) values (2,1,'mypic2.jpg');
insert into images_tags (image_id,tag_id) values (2,0);
insert into images_tags (image_id,tag_id) values (2,1);
insert into images (id,owner,filename) values (3,2,'mypic3.jpg');
insert into images_tags (image_id,tag_id) values (3,0);
insert into images (id,owner,filename) values (4,1,'mypic4.jpg');
insert into images_tags (image_id,tag_id) values (4,0);
insert into images (id,owner,filename) values (5,1,'mypic5.jpg');
insert into images_tags (image_id,tag_id) values (5,0);
insert into images (id,owner,filename) values (6,1,'mypic6.jpg');
insert into images_tags (image_id,tag_id) values (6,0);
insert into images (id,owner,filename) values (7,1,'mypic7.jpg');
insert into images_tags (image_id,tag_id) values (7,0);
insert into images (id,owner,filename) values (8,1,'mypic8.jpg');
insert into images_tags (image_id,tag_id) values (8,0);
insert into images (id,owner,filename) values (9,1,'mypic9.jpg');
insert into images_tags (image_id,tag_id) values (9,0);
insert into images (id,owner,filename) values (10,1,'mypic10.jpg');
insert into images_tags (image_id,tag_id) values (10,0);
insert into images (id,owner,filename) values (11,1,'mypic11.jpg');
insert into images_tags (image_id,tag_id) values (11,0);

-- test that we can hide images without messing up the page/offset and prev/next image links
insert into images (id,owner,filename,deleted_on) values (12,1,'elephant.jpg',now());
insert into images_tags (image_id,tag_id) values (12,0);
insert into images_tags (image_id,tag_id) values (12,1);
insert into images (id,owner,filename) values (13,1,'lion.jpg');
insert into images_tags (image_id,tag_id) values (13,0);
insert into images_tags (image_id,tag_id) values (13,1);

-- select the complete data
with image_details as (
    select
      image.id as imageid
    , "user".id as userid
    , filename
    , "user".name as username
    , deleted_on
    , hidden_on
    , tag.id as tagid
    , tag.name as tagname
    , rank() over (partition by "user".id, tag.id order by created_on, image.id) as pos
    from images_tags images_tags
     join images "image" on images_tags.image_id = image.id
     join tags   "tag"   on images_tags.tag_id   = tag.id
     join users  "user"  on image.owner = "user".id
),
gallery_details as (
  select
        userid
      , tagid
      , max(pos) as last_entry
    from image_details
    group by userid, tagid
)
  select
    pos
  , imageid
  , filename
  , username
  , tagname
  , lead(pos,1) over (partition by username,tagname order by pos) as next_entry
  , lag(pos,1) over (partition by username,tagname order by pos) as prev_entry
  , 1 as first_entry
  , last_entry
  , pos / 10 +1 as current_page
  , 1 as first_page
  , last_entry / 10 +1 as last_page
  from image_details image
    join gallery_details page on image.userid = page.userid
         and image.tagid = page.tagid
  where deleted_on is null and hidden_on is null
  order by tagname, pos
  