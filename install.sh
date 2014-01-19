#!/bin/bash

# install crew to home directory

echo "Downloading crew.zip"
curl -sSL https://github.com/joshbuddy/crew/archive/master.zip -o /tmp/crew.zip
if [ ! -d /tmp/.crew ]; then
  echo "Creating /tmp/.crew directory"
  unzip /tmp/crew.zip -d /tmp/.crew
fi

rm -rf /tmp/crew.zip

# install gems to home dir

USER_GEM_DIR=$(ruby -rubygems -e 'puts Gem.user_dir')
cd /tmp/.crew/crew-master
gem build crew.gemspec
CREW_GEM_FILE=$(find . -name *.gem)
echo $CREW_GEM_FILE

gem install --user-install $CREW_GEM_FILE
rm -rf /tmp/.crew

crew run fs_path_add "$USER_GEM_DIR/bin"
