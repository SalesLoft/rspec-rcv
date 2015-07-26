module RSpecRcv
  module RSpec
    module Metadata
      extend self

      def configure!
        ::RSpec.configure do |config|
          when_tagged_with_rcv = { rcv: lambda { |val| !!val } }

          config.after(:each, when_tagged_with_rcv) do |ex|
            example = ex.respond_to?(:metadata) ? ex : ex.example
            opts = example.metadata[:rcv]
            data_proc = lambda { |opts| instance_eval(&opts[:exportable_proc]) }

            Handler.new(ex.file_path, data_proc, metadata: opts).call
          end
        end
      end
    end
  end
end
