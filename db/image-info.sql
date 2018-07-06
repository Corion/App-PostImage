-- image page information
with (
    select
        image.id
      , image.externalfilename as externalfilename
      , user.name as username
      , tag.name  as tagname
      -- making pos() a static field would mean (yet) another table to record
      -- the position for each tag of the image. No fun, especially with all
      -- the maintenance functions that will need to go with it.
      , rank() over (partition by user, tag order by image.timestamp) as pos
    from images_tags it
    join images image on it.image_id = image.id
    join tags   tag   on it.tag_id   = tag.tag_id 
    join users  user  on image.owner = user.id
  as image_information
, select
        username
      , tagname
      , max(pos) as last_item
   from image_information
   group by
       username
     , tagname
   as gallery_information
)
select
    image.id
  , image.username
  , image.tagname
  , image.page
  , gallery.last_item
  , 1                as first_page
  , 1                as first_item
  , (last_item/10)+1 as last_page
  , case
      when image.page-1 < first_page then first_page 
      else image.page-1
    end as prev_page
  , case
      when image.page+1 > last_page then last_page
      else image.page+1
    end as next_page
  from      image_information image
  left join gallery_information gallery
      on    image.username = gallery.username
        and image.tagname  = gallery.tagname
where image.id = ?
  and image.tagname  = ?
  and image.username = ?
  and image.deleted is null
