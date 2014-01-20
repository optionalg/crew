#!/bin/bash

# install crew to home directory

echo "Installing crew"
LOCAL_GEM=$(find . -name *.gem | head -n 1)
if [ ! -e $LOCAL_GEM ]; then
  type rvm | head -n 1 | grep -q 'rvm is'
  if [ $? -eq "0" ]; then
    gem install $LOCAL_GEM
  else
    USER_GEM_DIR=$(ruby -rubygems -e 'puts Gem.user_dir')
    gem install -q --user-install $LOCAL_GEM
    $USER_GEM_DIR/bin/crew run fs_path_add "$USER_GEM_DIR/bin"
    if [ ! -d $HOME/.crew ]; then
    $USER_GEM_DIR/bin/crew init ~
    fi
  fi
  $USER_GEM_DIR/bin/crew run fs_path_add "$USER_GEM_DIR/bin"
else
  gem install crew -q --user-install -v0.0.1
  USER_GEM_DIR=$(ruby -rubygems -e 'puts Gem.user_dir')
  if [ ! -d $HOME/.crew ]; then
    $USER_GEM_DIR/bin/crew init ~
  fi
  $USER_GEM_DIR/bin/crew run fs_path_add "$USER_GEM_DIR/bin"
fi


echo "All done!"