require "rspec-rcv/version"

require "rspec-rcv/codecs/pretty_json"
require "rspec-rcv/codecs/yaml"
require "rspec-rcv/helpers/deep_except"

require "rspec-rcv/configuration"
require "rspec-rcv/test_frameworks/rspec"

require "rspec-rcv/handler"
require "rspec-rcv/data_changed_error"


module RSpecRcv
  extend self

  module RSpec
    autoload :Metadata, "rspec-rcv/test_frameworks/rspec"
  end

  def configure
    yield configuration
  end

  def configuration
    @configuration ||= Configuration.new
  end

  def config(overrides=nil)
    configuration.opts(overrides)
  end
end
