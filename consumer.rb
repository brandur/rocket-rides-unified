require_relative "./api"

class Consumer
  def initialize(name:)
    self.name = name
  end

  def run
    $stdout.puts "Starting consumer: #{name}"

    loop do
      num_consumed = run_once

      # Sleep for a while if we didn't find anything to consume on the last
      # run.
      if num_consumed == 0
        $stdout.puts "Sleeping for #{SLEEP_DURATION}"
        sleep(SLEEP_DURATION)
      end
    end
  end

  def run_once
    num_consumed = 0

    DB.transaction do
      checkpoint = Checkpoint.first(name: name)

      # "-" is a special symbol in Redis streams that dictates that we should
      # start from the earliest record in the stream. If we don't already have
      # a checkpoint, we start with that.
      start_id = "-"
      start_id = checkpoint.last_id unless checkpoint.nil?

      records = RDB.xrange(STREAM_NAME, start_id, "+", "COUNT", BATCH_SIZE)
      unless records.empty?
        records.each do |record|
          _id, fields = records.first

          # ["data", "{\"id\":123}"] -> {"data"=>"{\"id\":123}"}
          fields = Hash[*fields]

          $stdout.puts "Consumed record: #{fields["data"]}"
          num_consumed += 1
        end

        # upsert the last ID we consumed under our given consumer name
        Checkpoint.
          insert_conflict(target: :name, update: {
            last_id: Sequel[:excluded][:last_id]
          }).
          insert(name: name, last_id: records.last[0])
      end
    end

    num_consumed
  end

  private

  # Number of records to try to consume on each batch.
  BATCH_SIZE = 1000
  private_constant :BATCH_SIZE

  # Sleep duration in seconds to sleep in case we ran but didn't find anything
  # to stream.
  SLEEP_DURATION = 5
  private_constant :SLEEP_DURATION

  attr_accessor :name
end

#
# run
#

if __FILE__ == $0
  # so output appears in Forego
  $stderr.sync = true
  $stdout.sync = true

  name = ARGV[0] || abort("Usage: ruby consumer.rb CONSUMER_NAME")

  Consumer.new(name: name).run
end
