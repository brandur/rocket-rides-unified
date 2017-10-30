require "json"
require "sinatra"

require_relative "./config"

class API < Sinatra::Base
  set :server, %w[puma]
  set :show_exceptions, false

  post "/rides" do
    DB.transaction(isolation: :serializable) do
      ride = Ride.create

      StagedLogRecord.insert(
        action: ACTION_CREATE,
        object: OBJECT_RIDE,
        data: Sequel.pg_jsonb({
          id: ride.id,
        })
      )

      [201, JSON.generate(wrap_ok(Messages.ok))]
    end
  end
end

#
# constants
#

ACTION_CREATE = "create"
ACTION_UPDATE = "update"
ACTION_DELETE = "delete"

OBJECT_RIDE = "ride"

#
# models
#

class Ride < Sequel::Model
end

class StagedLogRecord < Sequel::Model
end

#
# other modules/classes
#

module Messages
  def self.ok
    "Payment accepted. Your pilot is on their way!"
  end
end

#
# helpers
#

# Wraps a message in the standard structure that we send back for success
# responses from the API. Still needs to be JSON-encoded before transmission.
def wrap_ok(message)
  { message: message }
end

#
# run
#

if __FILE__ == $0
  API.run!
end
