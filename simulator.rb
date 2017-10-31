require "net/http"
require "securerandom"

require_relative "./api"

class Simulator
  def run
    loop do
      run_once
      duration = rand(2)
      $stdout.puts "Sleeping for #{duration}"
      sleep(duration)
    end
  end

  def run_once
    http = Net::HTTP.new("localhost", "5000")
    request = Net::HTTP::Post.new("/rides")

    response = http.request(request)
    $stdout.puts "Response: status=#{response.code} body=#{response.body}"
  end
end

#
# run
#

if __FILE__ == $0
  # so output appears in Forego
  $stderr.sync = true
  $stdout.sync = true

  Simulator.new.run
end
