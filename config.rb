require "pg"
require "sequel"

DB = Sequel.connect(ENV["DATABASE_URL"] || abort("need DATABASE_URL"))
DB.extension :pg_json

# a verbose mode to help with debugging
if ENV["VERBOSE"] == "true"
  DB.loggers << Logger.new($stdout)
end
