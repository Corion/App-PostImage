create table users (
    id integer primary key not null
  ,	name varchar(16) not null
  -- , email varchar(128)
);

create table images (
    id integer primary key not null
  , owner integer not null
  , filename varchar(128) not null          -- where we store the file
  , external_filename varchar(128) not null -- how it shows up to the user
  , width integer not null
  , height integer not null
  , uploaded timestamp not null default (DATETIME('now'))

  , deleted_on timestamp
  , hidden_on timestamp
  , created_on timestamp default (DATETIME('now'))
  
  , foreign key (owner) references users(id)

);

create table tags (
    id integer primary key not null
  , is_internal boolean default false
  , name varchar(64) not null
);

create table images_tags (
    image_id integer references images(id)
  , tag_id integer references tags(id)
);


