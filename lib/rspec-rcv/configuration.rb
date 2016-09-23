module RSpecRcv
  class Configuration
    DEFAULTS = {
        exportable_proc: Proc.new { JSON.parse(response.body) },
        compare_with: Proc.new do |existing, new, opts|
          Helpers::DeepExcept.new(existing, opts[:ignore_keys]).to_h == Helpers::DeepExcept.new(new, opts[:ignore_keys]).to_h
        end,
        codec: Codecs::PrettyJson.new,
        ignore_keys: [],
        fail_on_changed_output: true,
        base_path: nil,
        fixture: nil,
        parse_existing: Proc.new do |existing|
          existing["data"]
        end
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

    def codec
      @opts[:codec]
    end

    def codec=(val)
      @opts[:codec] = val
    end

    def ignore_keys
      @opts[:ignore_keys]
    end

    def ignore_keys=(val)
      @opts[:ignore_keys] = val
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
