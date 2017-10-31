require_relative "./spec_helper"

require_relative "../consumer"

RSpec.describe Consumer do
  before do
    clear_database
    clear_redis
    suppress_stdout
  end
end
