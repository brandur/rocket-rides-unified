require_relative "./spec_helper"

require_relative "../streamer"

RSpec.describe Streamer do
  before do
    clear_database
    clear_redis
  end

  it "streams and removes a staged log record" do
    create_staged_log_record

    num_streamed = Streamer.new.run_once
    expect(num_streamed).to eq(1)

    expect(StagedLogRecord.count).to eq(0)
  end

  it "no-ops on an empty database" do
    num_streamed = Streamer.new.run_once
    expect(num_streamed).to eq(0)
  end

  private def create_staged_log_record
    StagedLogRecord.insert(
      action: ACTION_CREATE,
      object: OBJECT_RIDE,
      data: Sequel.pg_jsonb({
        id: 123,
      })
    )
  end
end
