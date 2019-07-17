# Installation Guide

## Ruby

Example with [rvm](https://rvm.io/) (other solutions : rbenv, packages..):

```sh
rvm install 2.3.5
```

Nokogiri on macOS

http://www.nokogiri.org/tutorials/installing_nokogiri.html tells us that `xz` can cause troubles, here is what to do

```
brew unlink xz
gem install nokogiri # or bundle install
brew link xz
```


## Node and Yarn

Yarn needs node. If you use Node Version Manager [NVM](https://github.com/creationix/nvm)  you can rely on the content of `.nvmrc`. Otherwise please make sure to use a compatible version, still best to use the same as indicated by `.nvrmc`.

* Install node

```sh
nvm install 6.13.0
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

On debian/ubuntu system :

```sh
sudo apt-get install libproj-dev postgis libmagickwand-dev libmagic-dev
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

### Database

#### Create database

```sh
bundle exec rake db:create db:migrate
```

#### Use seed

Run :

```sh
bundle exec rake db:seed
```

### Run

Launch Delayed jobs

```sh
bundle exec rake jobs:work
```

```sh
bin/webpack-dev-server // Launch webpack server to compile assets on the fly
bundle exec rails server // Launch rails server
```
