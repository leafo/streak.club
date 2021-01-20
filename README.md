# Streak Club

![test](https://github.com/leafo/streak.club/workflows/test/badge.svg)

A site for doing creative streaks of any kind. See it live: <http://streak.club>

[![Twitch Link](http://leafo.net/dump/twitch-banner.svg)](https://www.twitch.tv/moonscript)

Powered by:

* <http://leafo.net/lapis/>
* <http://moonscript.org>

## How To Run Locally

The development environment has only been tested on Linux. It may be easiest to
run the development environment within Docker.

Install the following dependencies:

* [Tup]
* [sassc]
* [discount] - or equivalent `markdown` executable.
* [PostgreSQL]
* [OpenResty]

Clone and navigate into this repository:

```bash
git clone git@github.com:leafo/streak.club.git
cd streak.club
```

Run these commands to install dependencies and build:

```bash
luarocks build --only-deps --server=https://luarocks.org/dev
npm install
tup init
tup
```

Create the schema and run the migrations:

```bash
make init_schema
make migrate
```

Start the server:

```bash
lapis server
```

Now `http://localhost:8080` should load.

If you edit any `moon`, `scss`, `coffee`, etc. files then run`tup` to
incrementally rebuild the changes. You can run `tup monitor -a` in the
background to watch the filesystem to rebuild automatically when saving a file.

### Running tests

This site uses [Busted] for its tests:

```bash
make test_db
busted
```

The `make test_db` command will copy the schema of the `streakclub` local
database into a freshly created test database (named `streakclub_test`). You'll
only need to run this command once and the beginning any any time the schema
has changed.

> **Note:** Migrations don't need to be run on the test database because you'll
> run them on the development database then transfer the schema over to the
> test database using `make test_db`.

### Setting up Google Cloud Storage

In production all files are stored on Google Cloud Storage. With no
configuration (default), files are stored on the file system using the storage
bucket mock provided by the `cloud_storage` rock.

To configure `cloud_storage` to talk to a live bucket make a file
`secret/storage_bucket.moon`, it must return a bucket instance. It might look
something like:


```moonscript
-- secret/storage_bucket.moon
import OAuth from require "cloud_storage.oauth"
import CloudStorage from require "cloud_storage.google"

o = OAuth "NUMBER@developer.gserviceaccount.com", "PRIVATEKEY.pem"
CloudStorage(o, "PROJECT_ID")\bucket "BUCKET_NAME"
```

### Setting up email

If you want to test sending emails you'll have to provide [Mailgun]
credentials. Create a file `secret/email.moon` and make it look something like
this: (it must return a table of options)

```moonscript
{ -- secret/email.moon
  key: "api:key-MY_KEY"
  domain: "streak.club"
  sender: "StreakClub <postmaster@streak.club>"
}
```

## License

GPLv2 - Leaf Corcoran 2021

[Busted]: http://olivinelabs.com/busted/
[Mailgun]: https://www.mailgun.com/
[OpenResty]: http://openresty.org/
[PostgreSQL]: https://www.postgresql.org/
[sassc]: https://github.com/sass/sassc
[Tup]: http://gittup.org/tup/
[discount]:http://www.pell.portland.or.us/~orc/Code/discount/
