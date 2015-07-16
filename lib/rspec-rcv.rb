require "rspec-rcv/version"
require "rspec-rcv/configuration"
require "rspec-rcv/test_frameworks/rspec"

require "rspec-rcv/handler"
require "rspec-rcv/data_changed_error"

module RSpecRcv
  extend self

  module RSpec
    autoload :Metadata, "rspec-stripe/test_frameworks/rspec"
  end

  def configure
    yield configuration
  end

  def configuration
    @configuration ||= Configuration.new
  end
end
