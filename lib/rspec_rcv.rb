require "rspec_rcv/version"

require "rspec_rcv/codecs/pretty_json"
require "rspec_rcv/codecs/yaml"

require "rspec_rcv/configuration"
require "rspec_rcv/test_frameworks/rspec"

require "rspec_rcv/handler"
require "rspec_rcv/data_changed_error"


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

  def config(overrides=nil)
    @configuration.opts(overrides)
  end
end
