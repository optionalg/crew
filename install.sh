#!/bin/bash

# install crew to home directory

echo "Installing crew"
LOCAL_GEM=$(find . -name *.gem | head -n 1)
if [ ! -e LOCAL_GEM ]; then
  type rvm | head -n 1 | grep -q 'rvm is'
  if [ $? -eq "0" ]; then
    gem install $LOCAL_GEM
  else
    USER_GEM_DIR=$(ruby -rubygems -e 'puts Gem.user_dir')
    gem install -q --user-install $LOCAL_GEM
    $USER_GEM_DIR/bin/crew run fs_path_add "$USER_GEM_DIR/bin"
  fi
else
  gem install crew -q --user-install -v0.0.1
  USER_GEM_DIR=$(ruby -rubygems -e 'puts Gem.user_dir')
  $USER_GEM_DIR/bin/crew run fs_path_add "$USER_GEM_DIR/bin"
fi

if [ ! -d $HOME/.crew ]; then
  crew init ~
fi

echo "All done!"