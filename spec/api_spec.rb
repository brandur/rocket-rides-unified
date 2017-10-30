require "rack/test"
require "securerandom"

require_relative "./spec_helper"

RSpec.describe API do
  include Rack::Test::Methods

  def app
    API
  end

  before do
    clear_database
  end

  it "succeeds and creates a ride and log record" do
    post "/rides"
    expect(last_response.status).to eq(201)
    expect(unwrap_ok(last_response.body)).to eq(Messages.ok)

    expect(Ride.count).to eq(1)
    expect(StagedLogRecord.count).to eq(1)
  end

  #
  # helpers
  #

  private def unwrap_ok(body)
    data = JSON.parse(body, symbolize_names: true)
    expect(data).to have_key(:message)
    data[:message]
  end
end
