# Bottlenose

Bottlenose is a web app for managing assignment submission and grading in
computer science courses. It provides a flexible mechanism for automatic grading
of programming assignments.

## Development Environment

Bottlenose is built expecting the following environment:

 * Ubuntu 16.04
 * A BTRFS (or ZFS) filesystem for /var
 * PostgreSQL
 * Ruby + Bundler

For deployment, Phusion Passenger + Nginx is recommended.

## Bottlenose Setup

The goal of this section is to have a working web-server running Bottlenose and
all of it's dependencies. All scripts in this sections start in the
`$BOTTLENOSE` directory unless explicitly stated otherwise.

### Basics

Some packages are generally good to have, and needed by many future steps in
the setup process.

```sh
sudo apt-get install build-essential git postgresql libpq-dev
```

### Postgres

```sh
# Switch to the postgres user to create the new bottlenose role.
sudo su - postgres

# Create the bottlenose role for postgres.
createuser -d bottlenose

# Exit back to the vagrant user.
exit
```

If you run into authentication trouble later, you may need to modify
the pg_hba.conf in /etc/postgres/.../ to allow local ident auth.

### Ruby

Best practice for Ruby in development is to use a version manager like
[rvm](http://rvm.io) or rbenv. Once you have the correct version installed, 

```sh
# Install Ruby's package manager "Bundler".
gem install bundler

# Install Bottlenose's dependencies.
# (from the bottlenose directory checked out from git)
bundle install
```

### Running Bottlenose

Bottlenose is mostly a standard Rails app.

Currently the bigest weirdness is the use of delayed job.

```sh
# Get a fresh database
rake db:create
rake db:migrate

# Start delayed job worker.
bin/delayed_job start

# Start the server
rails s

# App should be at localhost:3000, as per usual.
```

