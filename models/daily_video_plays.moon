import Model from require "lapis.db.model"
import DailyUploadDownloads from require "models"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE daily_video_plays (
--   upload_id integer NOT NULL,
--   date date NOT NULL,
--   count integer DEFAULT 0 NOT NULL
-- );
-- ALTER TABLE ONLY daily_video_plays
--   ADD CONSTRAINT daily_video_plays_pkey PRIMARY KEY (upload_id, date);
--
class DailyVideoPlays extends DailyUploadDownloads

