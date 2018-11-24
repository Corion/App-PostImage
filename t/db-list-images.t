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

# Maybe we can turn this into a generic "sequence+categories" database?!
my $image_info = $dbh->selectall_arrayref(<<'SQL', { Slice => {}});
-- image page information
with image_information as (
    select
        image.id
      , image.filename
      , image.external_filename as external_filename
      , user.name as username
      , tag.name  as tagname
      , deleted_on
      , hidden_on
      -- making pos() a static field would mean (yet) another table to record
      -- the position for each tag of the image. No fun, especially with all
      -- the maintenance functions that will need to go with it.
      , rank() over (partition by owner, it.tag_id order by image.created_on, image.id) as pos
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
  , ((last_item-1)/10)+1 as last_page
  , pos
  , cast( (pos-1) / 10 +1 as integer ) as page
  , case
      when cast( (pos-1) / 10 +1 as integer ) < 1 then 1
      -- first_page then first_page
      else cast( (pos-1) / 10 +1 as integer )
    end as prev_page
  , case
      when (pos-1) / 10 +1+1 > ((last_item-1)/10)+1 then ((last_item-1)/10)+1
      else (pos-1) / 10 +1+1
    end as next_page
  , filename
  , external_filename
  from      image_information   image
  left join gallery_information gallery
      on    image.username = gallery.username
        and image.tagname  = gallery.tagname
where 1=1 -- image.id = ?
--  and image.tagname  = ?
--  and image.username = ?
   and deleted_on is null
   and hidden_on is null
SQL

is 0+@$image_info, 14, "We have fourteen (visible) images";

my @corion = grep { $_->{username} eq 'Corion' } @$image_info;
is 0+@corion, 13, "Only one image by somebody other than Corion";

diag Dumper $image_info;

done_testing;