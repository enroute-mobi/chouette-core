# Installation Guide

This guide is based on mac/OS with [Homebrew](https://brew.sh/) and [RVM](https://rvm.io/)

## Ruby

Get a correct `.ruby-version` (Can we remove it from `.gitignore`?)
and install that version.

Example with [rvm](https://rvm.io/):

        rvm install 2.3.1

Add the bundler gem

        gem install bundler

Go into your local repro and install the gems

        bundle

## Node and Yarn

Yarn needs a node version ≥ 6, if you use Node Version Manager [NVM](https://github.com/creationix/nvm)  you can rely on the content of `.nvmrc`.

Otherwise please make sure to use a compatible version, still best to use the same as indicated by `.nvrmc`.

Then install yarn (`brew install yarn` does nicely on macOS).

## Webpack

... is managed by the webpacker gem, thusly at latest
 before starting your server and tests, setup webpacker with `bundle exec rake webpacker:install`.


It seems that for older versions of Rails this alternative command must be used:

      rake webpacker:yarn_install

According to `rake -T`:

      rake webpacker:yarn_install[arg1,arg2]                     # Support for older Rails versions

### Installation Caveats

#### Node Related Issue, libv8

`libv8` might cause you troubles, depending on your local configuration. If you have `libv8` installed (probably because of `node.js`) you might need to tell bundler/Rubygems to use the system version.


        bundle config build.libv8 --with-system-v8
        bundle

or

        gem install libv8 -v '<version>' -- --with-system-v8
        bundle

You will get the correct value of `<version>` from bundler's error message.

#### Node Related Issue, therubyracer

Even after `libv8` installation working, the gem `therubyracer` might not like the `libv8` version chosen.

In that case however we can let the gem make its own choice:

        gem uninstall libv8
        gem install therubyracer -v '<version>'

The version to be installed is indicated in the error message bundler gave us in the first place.

This will install an appropriate `libv8` version and we can continue with `bundle`.

## Rails

### Dependencies

As documented [here](https://github.com/dryade/georuby-ext/issues/2) we need some more libs before we can start the `rake` setup tasks. On mac/OS the easiest way is just to install `postgis` now with `homebrew` as this will
install all needed libraries.

Also if on Linux you might discover a problem as late as when launching `rake`.
In case of a stacktrace similar to this one

```
$ bundle exec rake --trace -T
rake aborted!
LoadError: library names list must not be empty
```

you need to install `proj` (macOS) or `libproj-dev` (Linux) on your system.


### Postgres

#### Create user

      createuser -s -U $USER -P chouette
                  ^    ^      ^
                  |    |      +---- prompt for passwd
                  |    +----- as your default postgres user (remove in case of different config)
                  +---------- superuser

When promted for the password enter the highly secure string `chouette`.


#### Create database

      bundle exec rake db:create
      bundle exec rake db:migrate

      RAILS_ENV=test bundle exec rake db:create
      RAILS_ENV=test bundle exec rake db:migrate

#### Install node.js packages

      bundle exec rake npm:install

#### Check installation

* Run tests

      bundle exec rake spec
      bundle exec rake teaspoon

* Start local server

      bundle exec rails server

### Authentication

See `config.chouette_authentication_settings`.

Use the database authentication or get an invitation to [STIF Portail](http://stif-portail-dev.af83.priv/).

### Run seed


#### Basic Database Content

      bundle exec rake db:seed


Two users are created : stif-boiv@af83.com/secret and stif-boiv+transporteur@af83.com/secret

#### Synchronize With STIF

If you have access to STIF CodifLigne and Reflex :

* Launch Sidekiq

      bundle exec sidekiq

* Execute the Synchronization Tasks

      bundle exec rake codifligne:sync
      bundle exec rake reflex:sync

**N.B.** These are asynchronious tasks, you can observe the launched jobs in your [Sidekiq Console](http://localhost:3000/sidekiq)

#### Data in various Apartments (Referentials)

To create `Referential` objects with some data (`Route`, `JourneyPattern`, `VehicleJourney`, etc) :

      bundle exec rake referential:create

# Troubleshooting

## Postgres

If Postgres complains about illegal type `hstore` in your tests that is probably because the shared extension is not installed, here is what to do:

      bundle exec rake db:test:purge

Thanks to `lib/tasks/extensions.rake`.

## macOS

### Nokogiri

http://www.nokogiri.org/tutorials/installing_nokogiri.html tells us that `xz` can cause troubles, here is what to do 

```
brew unlink xz
gem install nokogiri # or bundle install
brew link xz
```
