require_relative "./spec_helper"

require_relative "../consumer"

RSpec.describe Consumer do
  NAME = "consumer0"

  before do
    clear_database
    clear_redis
    suppress_stdout
  end

  it "consumes and creates a checkpoint" do
    create_log_record({ id: 123 })
    id = create_log_record({ id: 124 })

    num_consumed = Consumer.new(name: NAME).run_once
    expect(num_consumed).to eq(2)

    expect(Checkpoint.first(name: NAME).last_id).to eq(id)
  end

  it "consumes and updates a checkpoint (if one existed previously)" do
    # create a log record and set the checkpoint for this consumer to its ID
    id = create_log_record({ id: 123 })
    Checkpoint.create(name: NAME, last_id: id)

    # then create a new record to be consumed on a run by the consumer
    id = create_log_record({ id: 124 })

    num_consumed = Consumer.new(name: NAME).run_once
    expect(num_consumed).to eq(1)

    expect(Checkpoint.first(name: NAME).last_id).to eq(id)
  end

  it "no-ops on an empty database" do
    num_consumed = Consumer.new(name: NAME).run_once
    expect(num_consumed).to eq(0)
  end

  #
  # private
  #

  # Creates a log record by injecting it directly into the Redis stream.
  # Returns the _Redis ID_ of the new record that was added.
  private def create_log_record(data)
    id = RDB.xadd(STREAM_NAME, "*", "data", JSON.generate(data))
    id
  end
end
