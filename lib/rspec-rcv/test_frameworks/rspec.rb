require 'json'

module RSpecRcv
  module RSpec
    module Metadata
      extend self

      DEFAULTS = {
          exportable_proc: Proc.new { response.body },
          export_with: :to_json,
          fail_on_changed_output: true,
          export_fixture_to: nil,
          base_path: nil
      }

      def configure!
        ::RSpec.configure do |config|
          when_tagged_with_rcv = { rcv: lambda { |val| !!val } }

          config.after(:each, when_tagged_with_rcv) do |ex|
            example = ex.respond_to?(:metadata) ? ex : ex.example
            opts = DEFAULTS.merge(example.metadata[:rcv])
            path = if opts[:base_path]
                     File.join(opts[:base_path], opts[:export_fixture_to])
                   else
                     opts[:export_fixture_to]
                   end

            data = instance_eval(&opts[:exportable_proc])

            existing_data = nil
            if File.exists?(path)
              begin
                existing_data = JSON.parse(File.read(path))
              rescue JSON::ParserError
                # The file must not have been valid, so we will overwrite it
              end
            end

            if existing_data && opts[:fail_on_changed_output]
              if existing_data["data"] != data
                raise RSpecRcv::DataChangedError.new("Existing data will be overwritten. Turn off this feature with fail_on_changed_output=false")
              end
            end

            unless existing_data && existing_data["file"] == ex.file_path && existing_data["data"] == data
              File.open(path, 'w') do |file|
                output = { recorded_at: Time.now, file: ex.file_path, data: data }
                file.write(output.send(opts[:export_with]))
              end
            end
          end
        end
      end
    end
  end
end
