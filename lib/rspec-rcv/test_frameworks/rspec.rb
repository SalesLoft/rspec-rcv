require 'json'

module RSpecRcv
  module RSpec
    module Metadata
      extend self

      class Handler
        DEFAULTS = {
            exportable_proc: Proc.new { response.body },
            export_with: :to_json,
            fail_on_changed_output: true,
            export_fixture_to: nil,
            base_path: nil
        }

        def initialize(file_path, data, metadata: {})
          @file_path = file_path
          @opts = DEFAULTS.merge(metadata)
          @data = data.call(@opts)
        end

        def call
          return if existing_data && existing_data["file"] == file_path && existing_data["data"] == data

          if existing_data && opts[:fail_on_changed_output]
            if existing_data["data"] != data
              raise RSpecRcv::DataChangedError.new("Existing data will be overwritten. Turn off this feature with fail_on_changed_output=false")
            end
          end

          File.open(path, 'w') do |file|
            output = { recorded_at: Time.now, file: file_path, data: data }
            file.write(output.send(opts[:export_with]))
          end
        end

        private

        attr_reader :file_path, :data, :opts

        def path
          if opts[:base_path]
            File.join(opts[:base_path], opts[:export_fixture_to])
          else
            opts[:export_fixture_to]
          end
        end

        def existing_data
          @existing_data ||= if File.exists?(path)
            begin
              existing_data = JSON.parse(File.read(path))
            rescue JSON::ParserError
              # The file must not have been valid, so we will overwrite it
            end
          end
        end
      end

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
