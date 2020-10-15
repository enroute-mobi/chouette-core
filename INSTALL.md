# Installation Guide

Step-by-step guide to setup a local dev environment. This is meant for Linux users, and has been tested with Pop_OS 20.04.

## Ruby

* Install RVM

The setup for RVM on Ubuntu/Pop_OS is described [here](https://github.com/rvm/ubuntu_rvm#install)

* Install Ruby

```sh
rvm install 2.6.4
```

## Node and Yarn

* Install [NVM](https://github.com/nvm-sh/nvm)

```sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.36.0/install.sh | bash
```

This script is supposed to add a few lines to your shell profile. If it's not working, you can add this at the end of your `.zshrc` or `.bashrc`.

```
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
```

More infos [here](https://github.com/nvm-sh/nvm#installing-and-updating).

* Install Node

```sh
nvm install 8.17.0
```

* Install [Yarn](https://yarnpkg.com/lang/en/docs/install/)

```sh
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt install yarn
```

* Install nodes packages

```sh
yarn install
```

## Postgres

* Install

```sh
sudo apt install postgresql postgresql-contrib
```

You can then connect as postgres (the default user).

```sh
sudo -i -u postgres
```

More infos [here](https://www.digitalocean.com/community/tutorials/how-to-install-postgresql-on-ubuntu-20-04-quickstart)

* Create user

```sh
postgres@server:~$ createuser -s -P chouette

```

When prompted for the password enter the highly secure string `chouette`.

To reconnect your regular user just type `exit`.

## Rails

* Dependencies

```sh
sudo apt install libproj-dev postgis libmagickwand-dev libmagic-dev libpq-dev
```

* Bundle

Clone chouette-core repo, go into the new folder.
The RVM gemset is created at that point, and the shell output should look like this :

```
ruby-2.6.4 - #gemset created /home/user/.rvm/gems/ruby-2.6.4@chouette
ruby-2.6.4 - #generating chouette wrappers - please wait
```

Add the bundler gem

```sh
gem install bundler
```

Install gems

```sh
bundle install
```

### Database

* Create database

```sh
bundle exec rake db:create db:migrate
```

* Seed

```sh
bundle exec rake db:seed
```

### Run

Launch Delayed jobs

```sh
bundle exec rake jobs:work
```

Launch webpack server to compile assets on the fly

```sh
bin/webpack-dev-server
```

Launch rails server

```sh
bundle exec rails server
```

You will then have access to your local server on `http://localhost:3000`, where you can create an account.

The next step could be to import a set of sample data to populate the local database.

Well done :)
