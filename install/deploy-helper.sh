#!/bin/bash -e

export BASEDIR=$PREFIX/var/www/stif-boiv

export RUN_USER=www-data
export RUN_GROUP=src

export SUDO=""

function setup() {
    grep -q $RUN_USER /etc/passwd || exit -1
    mkdir -p $BASEDIR
    mkdir -p $BASEDIR/releases $BASEDIR/shared

    $SUDO mkdir -p $PREFIX/etc/stif-boiv
    ln -fs $PREFIX/etc/stif-boiv $BASEDIR/shared/config

    mkdir -p $BASEDIR/shared/config/environments

    mkdir -p $BASEDIR/shared/config/initializers

    mkdir -p $BASEDIR/shared/public
    mkdir -p $BASEDIR/shared/public/uploads
    mkdir -p $BASEDIR/shared/public/assets

    mkdir -p $BASEDIR/shared/tmp/uploads

    $SUDO chown $RUN_USER:$RUN_GROUP $BASEDIR/shared/public/uploads $BASEDIR/shared/tmp/uploads

    default_config
}

function default_config() {
    DATABASE_PASSWORD=${DATABASE_PASSWORD:-FIXME}
    DATABASE_HOST=${DATABASE_HOST:-"localhost"}

    cd $BASEDIR/shared/config

    if [ ! -f secrets.yml ]; then
        cat > secrets.yml <<EOF
production:
  secret_key_base: `echo $RANDOM | sha512sum | cut -f1 -d' '`
EOF
    fi

    if [ ! -f database.yml ]; then
        cat > database.yml <<EOF
production:
  adapter: postgis
  encoding: unicode
  port: 5432

  host: $DATABASE_HOST
  schema_search_path: 'public,shared_extensions'

  username: stif-boiv
  password: $DATABASE_PASSWORD
  postgis_schema: 'shared_extensions'
EOF
    fi

}

function install() {
    tar_file=$1

    # stif-boiv-20160617154541.tar
    release_name=`echo $tar_file | sed 's/.*-\([0-9]*\)\.tar/\1/g'`

    RELEASE_PATH=$BASEDIR/releases/$release_name

    if [ -d $RELEASE_PATH ]; then
        echo "Release directory $RELEASE_PATH already exists"
        return
    fi

    mkdir -p $RELEASE_PATH

    tar -xf $tar_file -C $RELEASE_PATH

    cd $RELEASE_PATH

    mkdir -p tmp

    # merge assets with existing ones
    rsync -a public/assets/ $BASEDIR/shared/public/assets/

    # relink shared dirs
    for directory in public/uploads tmp/uploads public/assets; do
        local_directory=$BASEDIR/shared/$directory
        release_directory=$directory

        rm -rf $release_directory
        ln -s $local_directory $release_directory
    done

    # relink shared files
    for file in secrets.yml database.yml environments/production.rb initializers/sidekiq.rb; do
        local_file=$BASEDIR/shared/config/$file
        release_file=config/$file

        rm $release_file && ln -fs $local_file $release_file
    done

    echo "Release installed into $RELEASE_PATH"
}

command=$1
shift

#set -x
$command $@
