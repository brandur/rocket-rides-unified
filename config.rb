require "logger"
require "pg"
require "redis"
require "sequel"

DB = Sequel.connect(ENV["DATABASE_URL"] || abort("need DATABASE_URL"))
DB.extension :pg_json

RDB = Redis.new(url: ENV["REDIS_URL"] || abort("need REDIS_URL"))

STREAM_NAME = ENV["STREAM_NAME"] || "rocket-rides-log"
STREAM_MAXLEN = 10000

# a verbose mode to help with debugging
if ENV["VERBOSE"] == "true"
  DB.loggers << Logger.new($stdout)
end
