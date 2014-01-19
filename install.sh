#!/bin/bash

# install crew to home directory

echo "Creating "
curl -sSL https://github.com/joshbuddy/crew/archive/master.zip -o /tmp/crew.zip
if [ ! -e /tmp/.crew ]; then;
  unzip /tmp/crew.zip -d /tmp/.crew
fi

rm -rf /tmp/crew.zip

# install gems to home dir

$USER_GEM_DIR=$(ruby -rubygems -e 'puts Gem.user_dir')
cd /tmp/.crew
gem build crew.gemspec
$CREW_GEM_FILE = $(find . -name *.gem)
gem install --user-install $CREW_GEM_FILE
rm -rf /tmp/.crew

crew run fs_path_add "$USER_GEM_DIR/bin"
