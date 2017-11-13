# rocket-rides-log [![Build Status](https://travis-ci.org/brandur/rocket-rides-log.svg?branch=master)](https://travis-ci.org/brandur/rocket-rides-log)

This is a project based on the original [Rocket Rides][rides] repository to
demonstrate what it might look like to implement a log-based architecture. See
[the associated article][log] for full details.

The core `api` process publishes records to a Redis stream in the same
transaction (with the help of the `streamer`) that it uses to persist its
canonical data to Postgres so that the system can provide a strong guarantee
that information in the log is indeed correct. Consumers read the stream and
calculate a result while persisting their location in it in their own
transaction.

## Architecture

If you look in `Procfile`, you'll see these processes:

* `api`: The main Rocket Rides API. It responds to requests, writes canonical
  data to Postgres, and stages records for emission into the unified log.
* `streamer`: Reads staged jobs in batches and writes them to a Redis stream
  (the unified log). The staging indirection means that if a transaction in the
  `api` rolls back, no invalid data will be left in the Redis stream.
* `consumer`: A consumer reads records from a Redis stream and tracks the
  aggregate total distance of all rides that have ever been made. It persists
  its location in the stream so that it can start where it left off in case of
  a crash.
    
    We run two copies of the consumer do demonstrate that even with failure
    artificially induced in the system, the architecture is robustness enough
    so that any number of independent consumers will always agree on the same
    result.
* `simulator`: Randomly issues requests to the `api`. This creates new rides of
  random distance and gives `streamer` and `consumer` a chance to do something.

After you run `forego start` you should see the `simulator` issuing jobs
against `api` right away. This will stage records in Postgres that the streamer
will post into a Redis stream. You'll see the consumers start to pick these up
and print their calculated `total_distance` into the console.

The system is built to simulate failure to demonstrate its correctness. 10% of
the time, the `streamer` will fail after posting records into the stream, which
will cause it to retry the operation and double-send those records. Likewise,
10% of the time each consumer will fail after calculating its new total
distance, but before getting a chance to persist its stream location. Despite
these problems, if you wait long enough, both consumers will always eventually
reach consensus and produce correct totals.

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

[log]: https://brandur.org/redis-streams
[rides]: https://github.com/stripe/stripe-connect-rocketrides

<!--
# vim: set tw=79:
-->
