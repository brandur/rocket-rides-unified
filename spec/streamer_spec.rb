require_relative "./spec_helper"

require_relative "../streamer"

RSpec.describe Streamer do
  before do
    clear_database
    clear_redis
    suppress_stdout
  end

  it "streams and removes a staged log record" do
    id = 123
    create_staged_log_record(id: id)

    num_streamed = Streamer.new.run_once
    expect(num_streamed).to eq(1)

    expect(StagedLogRecord.count).to eq(0)

    res = RDB.xrange(STREAM_NAME, "-", "+", "COUNT", "1")
    expect(res.count).to eq(1)
    _id, fields = res.first

    # ["data", "{\"id\":123}"] -> {"data"=>"{\"id\":123}"}
    fields = Hash[*fields]
    data = JSON.parse(fields["data"])
    expect(data["id"]).to eq(id)
  end

  it "no-ops on an empty database" do
    num_streamed = Streamer.new.run_once
    expect(num_streamed).to eq(0)
  end

  private def create_staged_log_record(id:)
    StagedLogRecord.insert(
      action: ACTION_CREATE,
      object: OBJECT_RIDE,
      data: Sequel.pg_jsonb({
        id: 123,
      })
    )
  end
end
