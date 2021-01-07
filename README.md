# Streak Club

![test](https://github.com/leafo/streak.club/workflows/test/badge.svg)

A site for doing creative streaks of any kind. See it live: <http://streak.club>

Still in early development!

[![Twitch Link](http://leafo.net/dump/twitch-banner.svg)](https://www.twitch.tv/moonscript)

Powered by:

* <http://leafo.net/lapis/>
* <http://moonscript.org>

## How To Run Locally

Install the following dependencies:

* [Tup]
* [sassc]
* [coffeescript]
* [uglify-es]
* [discount] - or equivalent `markdown` executable.
* [PostgreSQL]
* [OpenResty]

Clone and navigate into this repository:

```bash
git clone git@github.com:leafo/streak.club.git
cd streak.club
```

Install the dependencies listed in [/BoxFile](/BoxFile) with LuaRocks.

Run these commands to build:

```bash
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

If you edit any MoonScript or SCSS files you should call `tup` to rebuild
the changes. You can run `tup monitor -a` to watch the filesystem to rebuild.

### Running tests

This site uses [Busted] for its tests:

```bash
make test_db
busted
```

The `make test_db` command will copy the schema of the `moonrocks` local
database into the test database, wiping out what whatever was there. You'll
only need to run this command once and the beginning any any time the schema
has changed.

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
credentials. A test account is free. Create a file `secret/email.moon` and
make it look something like this: (it must return a table of options)

```moonscript
{ -- secret/email.moon
  key: "api:key-MY_KEY"
  domain: "mydomain.mailgun.org"
  sender: "MoonRocks <postmaster@mydomain.mailgun.org>"
}
```

## License

GPLv2 - Leaf Corcoran 2020

[Busted]: http://olivinelabs.com/busted/
[coffeescript]: http://coffeescript.org/#installation
[Mailgun]: https://www.mailgun.com/
[OpenResty]: http://openresty.org/
[PostgreSQL]: https://www.postgresql.org/
[sassc]: https://github.com/sass/sassc
[Tup]: http://gittup.org/tup/
[uglify-es]: https://github.com/mishoo/UglifyJS2/tree/harmony
[discount]:http://www.pell.portland.or.us/~orc/Code/discount/
