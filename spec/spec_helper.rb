require "rspec"
require 'webmock/rspec'

ENV["DATABASE_URL"] = "postgres://localhost/rocket-rides-log-test"
ENV["RACK_ENV"] = "test"

require_relative "../api"

def clear_database
  DB.run("TRUNCATE rides CASCADE")
  DB.run("TRUNCATE staged_log_records CASCADE")
end
