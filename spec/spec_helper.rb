require "rspec"
require 'webmock/rspec'

ENV["DATABASE_URL"] = "postgres://localhost/rocket-rides-log-test"
ENV["RACK_ENV"] = "test"
ENV["REDIS_URL"] = "redis://localhost:6388/15"

require_relative "../api"

def clear_database
  DB.run("TRUNCATE checkpoints CASCADE")
  DB.run("TRUNCATE rides CASCADE")
  DB.run("TRUNCATE staged_log_records CASCADE")
end

def clear_redis
  RDB.flushdb
end

def suppress_stdout
  $stdout = StringIO.new unless verbose?
end

def verbose?
  ENV["VERBOSE"] == "true"
end
