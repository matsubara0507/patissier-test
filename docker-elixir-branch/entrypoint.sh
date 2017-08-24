#!/bin/bash

set -eux

git clone --depth=1 --branch $ELIXIR_BRANCH --single-branch https://github.com/elixir-lang/elixir.git
cd elixir
make install clean

cd ../

mix local.hex --force
mix archive.install https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez --force

yes | mix phoenix.new hello
cd hello
mix local.rebar --force
mix phoenix.server
