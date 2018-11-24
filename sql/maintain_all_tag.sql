-- maintain the implicit "all images/timeline" tag
insert into images_tags
select
    (image_id, 0)
from images
where image_id not in (select distinct image_id from images_tags where tag_id=0)