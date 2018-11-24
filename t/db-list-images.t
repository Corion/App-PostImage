#!perl
use strict;
use warnings;
use Data::Dumper;
use DBIx::RunSQL;

use Test::More tests => 2;

my $dbh = DBIx::RunSQL->create(
    dsn     => 'dbi:SQLite:dbname=:memory:',
    sql     => 'sql/create.sql',
    #force   => 1,
    #verbose => 1,
);

# Populate the test database with the test data:

DBIx::RunSQL->run(
    dbh => $dbh,
    sql => 'sql/populate.sql',
);

my $image_info = $dbh->selectall_arrayref(<<'SQL',);
-- image page information
with image_information as (
    select
        image.id
      , image.external_filename as external_filename
      , user.name as username
      , tag.name  as tagname
      -- making pos() a static field would mean (yet) another table to record
      -- the position for each tag of the image. No fun, especially with all
      -- the maintenance functions that will need to go with it.
      , rank() over (partition by owner, it.tag_id order by image.created_on) as pos
    from images_tags it
    join images image on it.image_id = image.id
    join tags   tag   on it.tag_id   = tag.id 
    join users  user  on image.owner = user.id
) 
, gallery_information as ( select
        username
      , tagname
      , max(pos) as last_item
   from image_information
   group by
       username
     , tagname
)
select
    image.id
  , image.username
  , image.tagname
  , gallery.last_item
  , 1                as first_page
  , 1                as first_item
  , (last_item/10)+1 as last_page
  , cast( pos / 10 as integer ) as page
  , case
      when page-1 < first_page then first_page 
      else page-1
    end as prev_page
  , case
      when page+1 > last_page then last_page
      else page+1
    end as next_page
  from      image_information   image
  left join gallery_information gallery
      on    image.username = gallery.username
        and image.tagname  = gallery.tagname
--where image.id = ?
--  and image.tagname  = ?
--  and image.username = ?
  -- and image.deleted is null
SQL

diag Dumper $image_info;