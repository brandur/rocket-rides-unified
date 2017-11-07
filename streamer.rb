require "json"
require_relative "./api"

class Streamer
  def run
    loop do
      # simulate double-send some amount of the time
      num_streamed = run_once(send_twice: rand() < 0.10)

      # Sleep for a while if we didn't find anything to stream on the last
      # run.
      if num_streamed == 0
        $stdout.puts "Sleeping for #{SLEEP_DURATION}"
        sleep(SLEEP_DURATION)
      end
    end
  end

  # Runs the process one time: all staged records are iterated through, pushed
  # into the stream, and then removed.
  #
  # The special `send_twice` parameter is there to simulate failure in the
  # system. In some cases this loop might fail midway through so that some
  # records were added to Redis, and some weren't. The process will retry and
  # probably succeed that second time through, but even so the stream will now
  # contain duplicated records. `send_twice` adds all staged records into the
  # stream twice to simulate this type of event.
  def run_once(send_twice: false)
    num_streamed = 0

    # Need at least repeatable read isolation level so that our DELETE after
    # enqueueing will see the same records as the original SELECT.
    DB.transaction(isolation_level: :repeatable_read) do
      records = StagedLogRecord.order(:id).limit(BATCH_SIZE)

      unless records.empty?
        RDB.multi do
          records.each do |record|
            stream(record.data)
            num_streamed += 1

            # simulate a double-send by adding the same record again
            if send_twice
              stream(record.data)
              num_streamed += 1
            end

            $stdout.puts "Enqueued record: #{record.action} #{record.object}"
          end
        end

        StagedLogRecord.where(Sequel.lit("id <= ?", records.last.id)).delete
      end
    end

    num_streamed
  end

  #
  # private
  #

  # Number of records to try to stream on each batch.
  BATCH_SIZE = 1000
  private_constant :BATCH_SIZE

  # Sleep duration in seconds to sleep in case we ran but didn't find anything
  # to stream.
  SLEEP_DURATION = 5
  private_constant :SLEEP_DURATION

  private def stream(data)
    # XADD mystream MAXLEN ~ 10000  * data <JSON-encoded blob>
    #
    # MAXLEN ~ 10000 caps the stream at roughly that number (the "~" trades
    # precision for speed) so that it doesn't grow in a purely unbounded way.
    RDB.xadd(STREAM_NAME, "MAXLEN", "~", STREAM_MAXLEN, "*", "data", JSON.generate(data))
  end
end

#
# run
#

if __FILE__ == $0
  # so output appears in Forego
  $stderr.sync = true
  $stdout.sync = true

  Streamer.new.run
end
