#!/bin/sh

gsutil cors set gs-cors.json gs://streakclub
gsutil cors set gs-cors.json gs://streakclub_dev

gsutil cors get gs://streakclub
gsutil cors get gs://streakclub_dev
