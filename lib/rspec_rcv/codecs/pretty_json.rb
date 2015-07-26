require 'json'

module RSpecRcv
  module Codecs
    class PrettyJson
      def export_with(hash)
        JSON.pretty_generate(hash)
      end

      def decode_with(str)
        JSON.parse(str)
      end
    end
  end
end
