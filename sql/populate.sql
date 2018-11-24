-- This is for running the unit tests
-- Add some users
insert into users (id,name) values (1,'Corion');
insert into users (id,name) values (2,'SomeoneElse');

-- all images must live in the magic "_all" category
-- I should set up a nice trigger to maintain that, instead of doing manual
-- insertion here...
insert into tags (id,is_internal,name) values (0, true, '_all');
insert into tags (id,is_internal,name) values (1, false, 'kittens');

insert into images (id,owner,filename,external_filename,width,height) values (1,1,'mypic1.jpg','pic1.jpg',500,500);
insert into images_tags (image_id,tag_id) values (1,0);
insert into images (id,owner,filename,external_filename,width,height) values (2,1,'mypic2.jpg','pic2.jpg',500,500);
insert into images_tags (image_id,tag_id) values (2,0);
insert into images_tags (image_id,tag_id) values (2,1);
insert into images (id,owner,filename,external_filename,width,height) values (3,2,'mypic3.jpg','pic3.jpg',500,500);
insert into images_tags (image_id,tag_id) values (3,0);
insert into images (id,owner,filename,external_filename,width,height) values (4,1,'mypic4.jpg','pic4.jpg',500,500);
insert into images_tags (image_id,tag_id) values (4,0);
insert into images (id,owner,filename,external_filename,width,height) values (5,1,'mypic5.jpg','pic5.jpg',500,500);
insert into images_tags (image_id,tag_id) values (5,0);
insert into images (id,owner,filename,external_filename,width,height) values (6,1,'mypic6.jpg','pic6.jpg',500,500);
insert into images_tags (image_id,tag_id) values (6,0);
insert into images (id,owner,filename,external_filename,width,height) values (7,1,'mypic7.jpg','pic7.jpg',500,500);
insert into images_tags (image_id,tag_id) values (7,0);
insert into images (id,owner,filename,external_filename,width,height) values (8,1,'mypic8.jpg','pic8.jpg',500,500);
insert into images_tags (image_id,tag_id) values (8,0);
insert into images (id,owner,filename,external_filename,width,height) values (9,1,'mypic9.jpg','pic9.jpg',500,500);
insert into images_tags (image_id,tag_id) values (9,0);
insert into images (id,owner,filename,external_filename,width,height) values (10,1,'mypic10.jpg','pic10.jpg',500,500);
insert into images_tags (image_id,tag_id) values (10,0);
insert into images (id,owner,filename,external_filename,width,height) values (11,1,'mypic11.jpg','pic11.jpg',500,500);
insert into images_tags (image_id,tag_id) values (11,0);

-- test that we can hide images without messing up the page/offset and prev/next image links
insert into images (id,owner,filename,external_filename,deleted_on,width,height) values (12,1,'elephant.jpg','mouse.jpg',datetime('now'),500,500);
insert into images_tags (image_id,tag_id) values (12,0);
insert into images_tags (image_id,tag_id) values (12,1);
insert into images (id,owner,filename,external_filename,width,height) values (13,1,'lion.jpg','cat.jpg',500,500);
insert into images_tags (image_id,tag_id) values (13,0);
insert into images_tags (image_id,tag_id) values (13,1);
