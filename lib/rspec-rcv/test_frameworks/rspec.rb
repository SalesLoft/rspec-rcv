module RSpecRcv
  module RSpec
    module Metadata
      extend self

      DEFAULTS = {
          exportable_proc: Proc.new { response.body },
          export_fixture_to: nil,
          fail_on_changed_output: true,
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

            if File.exists?(path) && opts[:fail_on_changed_output]
              existing_data = File.read(path)

              if existing_data != data
                raise RSpecRcv::DataChangedError.new("Existing data will be overwritten. Turn off this feature with fail_on_changed_output=false")
              end
            end

            File.open(path, 'w') { |file| file.write(data) }
          end
        end
      end
    end
  end
end
