module RSpecRcv
  class Configuration
    DEFAULTS = {
        exportable_proc: Proc.new { response.body },
        compare_with: Proc.new { |existing, new| existing == new },
        export_with: Proc.new do |hash|
          begin
            hash[:data] = JSON.parse(hash[:data])
          rescue JSON::ParserError
          end
          JSON.pretty_generate(hash)
        end,
        fail_on_changed_output: true,
        base_path: nil,
        fixture: nil
    }

    def initialize
      reset!
    end

    def configure_rspec_metadata!
      unless @rspec_metadata_configured
        RSpecRcv::RSpec::Metadata.configure!
        @rspec_metadata_configured = true
      end
    end

    def reset!
      @opts = DEFAULTS.dup
    end

    def opts(overrides={})
      @opts.merge(overrides)
    end

    def exportable_proc
      @opts[:exportable_proc]
    end

    def exportable_proc=(val)
      @opts[:exportable_proc] = val
    end

    def export_with
      @opts[:export_with]
    end

    def export_with=(val)
      @opts[:export_with] = val
    end

    def compare_with
      @opts[:compare_with]
    end

    def compare_with=(val)
      @opts[:compare_with] = val
    end

    def base_path
      @opts[:base_path]
    end

    def base_path=(val)
      @opts[:base_path] = val
    end

    def fail_on_changed_output
      @opts[:fail_on_changed_output]
    end

    def fail_on_changed_output=(val)
      @opts[:fail_on_changed_output] = val
    end
  end
end
