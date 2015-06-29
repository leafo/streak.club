db = require "lapis.db"
import Model from require "lapis.db.model"
import DailyUploadDownloads from require "models"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE daily_audio_plays (
--   upload_id integer NOT NULL,
--   date date NOT NULL,
--   count integer DEFAULT 0 NOT NULL
-- );
-- ALTER TABLE ONLY daily_audio_plays
--   ADD CONSTRAINT daily_audio_plays_pkey PRIMARY KEY (upload_id, date);
--
class DailyAudioPlays extends DailyUploadDownloads

