#!/bin/zsh

# This files contains commands that will be run after the devcontainer is created.

bundle install

bin/rails db:prepare 

echo "Done! Enjoy coding your Rails application!"