require 'yaml'

module RSpecRcv
  module Codecs
    class Yaml
      def export_with(hash)
        YAML.dump(hash)
      end

      def decode_with(str)
        YAML.load(str)
      end
    end
  end
end
