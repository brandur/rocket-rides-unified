# rocket-rides-log [![Build Status](https://travis-ci.org/brandur/rocket-rides-log.svg?branch=master)](https://travis-ci.org/brandur/rocket-rides-log)

## Setup

Requirements:

1. Postgres (`brew install postgres`)
2. Ruby (`brew install ruby`)
3. forego (`brew install forego`)

The last requirement is the `streams` branch of Redis (as of Oct 30th, 2017
this feature is not yet in `unstable` or released):

```
git clone https://github.com/antirez/redis.git
cd redis
git checkout streams
make
redis-server --port 6388
```

Install dependencies, create a database and schema, and start running the
processes:

```
bundle install
createdb rocket-rides-log
psql rocket-rides-log < schema.sql
forego start
```

## Development & testing

Install dependencies, create a test database and schema, and then run the test
suite:

```
bundle install
createdb rocket-rides-log-test
psql rocket-rides-log-test < schema.sql
bundle exec rspec spec/
```

<!--
# vim: set tw=79:
-->
