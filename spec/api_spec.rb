require "rack/test"
require "securerandom"

require_relative "./spec_helper"

RSpec.describe API do
  include Rack::Test::Methods

  VALID_PARAMS = {
    "distance" => 123.0,
  }.freeze

  def app
    API
  end

  before do
    clear_database
  end

  it "succeeds and creates a ride and log record" do
    post "/rides", VALID_PARAMS
    expect(last_response.status).to eq(201)
    expect(unwrap_ok(last_response.body)).to eq(
      Messages.ok(distance: VALID_PARAMS["distance"].round(1).to_s)
    )

    expect(Ride.count).to eq(1)
    expect(StagedLogRecord.count).to eq(1)
  end

  describe "failure" do
    it "denies requests that are missing parameters" do
      post "/rides", {}
      expect(last_response.status).to eq(422)
      expect(unwrap_error(last_response.body)).to \
        eq(Messages.error_require_param(key: "distance"))
    end

    it "denies requests that are the wrong type" do
      post "/rides", { "distance" => "foo" }
      expect(last_response.status).to eq(422)
      expect(unwrap_error(last_response.body)).to \
        eq(Messages.error_require_float(key: "distance"))
    end
  end

  #
  # helpers
  #

  private def unwrap_error(body)
    data = JSON.parse(body, symbolize_names: true)
    expect(data).to have_key(:error)
    data[:error]
  end

  private def unwrap_ok(body)
    data = JSON.parse(body, symbolize_names: true)
    expect(data).to have_key(:message)
    data[:message]
  end
end
