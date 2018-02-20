# Installation Guide

## Ruby

Example with [rvm](https://rvm.io/) (other solutions : rbenv, packages..):

```sh
rvm install 2.3.1
```

## Node and Yarn

Yarn needs node. If you use Node Version Manager [NVM](https://github.com/creationix/nvm)  you can rely on the content of `.nvmrc`. Otherwise please make sure to use a compatible version, still best to use the same as indicated by `.nvrmc`.

* Install node

```sh
nvm install 6.12.0
```

* Install [yarn](https://yarnpkg.com/lang/en/docs/install/)

```sh
// On macOS
brew install yarn

// On Debian/ubuntu
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn
```

* Install nodes packages

```sh
yarn install
```

### Installation Caveats

#### Node Related Issue, libv8

`libv8` might cause you troubles, depending on your local configuration. If you have `libv8` installed (probably because of `node.js`) you might need to tell bundler/Rubygems to use the system version.

```sh
bundle config build.libv8 --with-system-v8
bundle
```

or

```sh
gem install libv8 -v '<version>' -- --with-system-v8
bundle
```

You will get the correct value of `<version>` from bundler's error message.

#### Node Related Issue, therubyracer

Even after `libv8` installation working, the gem `therubyracer` might not like the `libv8` version chosen.

In that case however we can let the gem make its own choice:

```sh
gem uninstall libv8
gem install therubyracer -v '<version>'
```

The version to be installed is indicated in the error message bundler gave us in the first place.

This will install an appropriate `libv8` version and we can continue with `bundle`.

## Postgres

### Create user

      createuser -s -U $USER -P chouette
                  ^    ^      ^
                  |    |      +---- prompt for passwd
                  |    +----- as your default postgres user (remove in case of different config)
                  +---------- superuser

When promted for the password enter the highly secure string `chouette`.

## Rails

### Dependencies

As documented [here](https://github.com/dryade/georuby-ext/issues/2) we need some more libs before we can start the `rake` setup tasks.


On mac/OS :

```sh
brew install postgis
```

<<<<<<< HEAD
### Authentication

See `config.chouette_authentication_settings`.

Use the database authentication or get an invitation to [STIF Portail](http://stif-portail-dev.af83.priv/).

### Run seed

Run :

      bundle exec rake db:seed

Two users are created : stif-boiv@af83.com/secret and stif-boiv+transporteur@af83.com/secret

If you have access to STIF CodifLigne and Reflex :

      bundle exec rake codifligne:sync
      bundle exec rake reflex:sync

To create Referential with some data (Route, JourneyPattern, VehicleJourney, etc) :

      bundle exec rake referential:create

# Troubleshooting

If PG complains about illegal type `hstore` in your tests that is probably because the shared extension is not installed, here is what to do:

#### Check installation

* Run tests

      bundle exec rake spec
      bundle exec rake teaspoon

* Start local server

      bundle exec rails server

=======
On debian/ubuntu system :

```sh
sudo apt-get install libproj-dev postgis
```

### Install gems

Add the bundler gem

```sh
gem install bundler
```

Go into your local repository and install the gems

```sh
bundle install
```

#### Nokogiri on macOS

http://www.nokogiri.org/tutorials/installing_nokogiri.html tells us that `xz` can cause troubles, here is what to do

```
brew unlink xz
gem install nokogiri # or bundle install
brew link xz
```

### Database

#### Create database

```sh
bundle exec rake db:create db:migrate
RAILS_ENV=test bundle exec rake db:create db:migrate
```

#### Load seed datas
>>>>>>> master

```sh
bundle exec rake db:seed:stif
```

#### Synchronise datas with lines and stop areas referentials

* Launch Sidekiq

```sh
bundle exec sidekiq
```

* Execute the Synchronization Tasks

```sh
bundle exec rake codifligne:sync
bundle exec rake reflex:sync
```

**N.B.** These are asynchronious tasks, you can observe the launched jobs in your [Sidekiq Console](http://localhost:3000/sidekiq)

#### Data in various Apartments (Referentials)

To create `Referential` objects with some data (`Route`, `JourneyPattern`, `VehicleJourney`, etc), you need to wait codifligne and reflex jobs finished. And then you can launch :

```sh
bundle exec rake referential:create
```

### Check installation

#### Run tests

#### Rspec

```sh
bundle exec rake spec
bundle exec rake teaspoon
```

If Postgres complains about illegal type `hstore` or `unaccent` in your tests that is probably because the shared extension is not installed, here is what to do:

      bundle exec rake db:test:purge

Thanks to `lib/tasks/extensions.rake`.

#### Jest (React integration specs)

`grunt jest` to run the whole specs.

`grunt` to watch for changes and automatically run corresponding tests.

#### Start local server

```sh
bin/webpack-dev-server // Launch webpack server to compile assets on the fly
bundle exec rails server // Launch rails server
```
You need to have an account on [STIF Portail](http://stif-portail-dev.af83.priv/) to connect to the Rails application.
