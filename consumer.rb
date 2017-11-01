require_relative "./api"

class Consumer
  # Increments a Redis stream ID. If we want to start reading a stream from
  # after some ID we know about we need to increment the ID ourselves and ask
  # Redis for the results from there.
  def self.increment(id)
    # IDs are of the form "1509473251518-0" and comprise a millisecond
    # timestamp plus a sequence number to differentiate within the timestamp.
    time, sequence = id.split("-")
    raise ArgumentError, "Expected ID to contain sequence" if sequence.nil?
    next_sequence = Integer(sequence) + 1
    "#{time}-#{next_sequence}"
  end

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
      start_id = self.class.increment(checkpoint.last_redis_id) unless checkpoint.nil?

      checkpoint = Checkpoint.new(name: name, last_ride_id: 0) if checkpoint.nil?

      records = RDB.xrange(STREAM_NAME, start_id, "+", "COUNT", BATCH_SIZE)
      unless records.empty?
        # get or create a new state for this consumer
        state = ConsumerState.first(name: name)
        state = ConsumerState.new(name: name, total_distance: 0.0) if state.nil?

        records.each do |record|
          redis_id, fields = record

          # ["data", "{\"id\":123}"] -> {"data"=>"{\"id\":123}"}
          fields = Hash[*fields]

          data = JSON.parse(fields["data"])

          # if the ride's ID is lower or equal to one that we know we consumed,
          # skip it; this is a double send
          if data["id"] <= checkpoint.last_ride_id
            $stdout.puts "Skipped record: #{fields["data"]} " \
              "(already consumed this ride ID)"
            next
          end

          state.total_distance += data["distance"]

          $stdout.puts "Consumed record: #{fields["data"]} " \
            "total_distance=#{state.total_distance.round(1)}m"
          num_consumed += 1

          checkpoint.last_redis_id = redis_id
          checkpoint.last_ride_id = data["id"]
        end

        # now that all records for this round are consumed, persist state
        state.save

        # and persist the changes to the checkpoint
        checkpoint.save
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
