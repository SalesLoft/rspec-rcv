require 'diffy'
require 'json-compare'

module RSpecRcv
  class Handler
    def initialize(file_path, data, metadata: {})
      @file_path = file_path
      @opts = RSpecRcv.config(metadata)
      @data = data.call(@opts)
    end

    def call
      return :no_change if existing_data && existing_data["file"] == file_path && existing_data["data"] == data

      output = { recorded_at: Time.now, file: file_path, data: data }
      output = opts[:codec].export_with(output) + "\n"

      if existing_data
        eq = opts[:compare_with].call(existing_data["data"], data, opts)

        if !eq && opts[:fail_on_changed_output]
          raise_error!(output, JsonCompare.get_diff(existing_data["data"], data, opts.fetch(:ignore_keys, [])))
        end

        return :same if eq
      end

      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') do |file|
        file.write(output)
      end

      return :to_disk
    end

    private

    attr_reader :file_path, :data, :opts

    def path
      if opts[:base_path]
        File.join(opts[:base_path], opts[:fixture])
      else
        opts[:fixture]
      end
    end

    def existing_file
      @existing_file ||= if File.exists?(path)
                           File.read(path)
                         end
    end

    def existing_data
      @existing_data ||= if File.exists?(path)
                           opts[:codec].decode_with(File.read(path))
                         end
    end

    def raise_error!(output, json_compare_output)
      diff = Diffy::Diff.new(existing_file, output).to_s

      combined = JsonOutputCombiner.new(json_compare_output).combine
      removed = combined[:remove]
      added = combined[:append]
      updated = combined[:update]

      raise RSpecRcv::DataChangedError.new(<<-EOF)
Existing data will be overwritten. Turn off this feature with fail_on_changed_output=false

#{diff}

The following keys were added: #{added.uniq.map(&:to_s)}
The following keys were removed: #{removed.uniq.map(&:to_s)}
The following keys were updated: #{updated.uniq.map(&:to_s)}

This fixture is located at #{path}
      EOF
    end
  end
end

class JsonOutputCombiner
  def initialize(output)
    @output = output
  end

  def combine
    compact_compare_output(@output, key: "")
  end

  private

  KEYS_TO_COMBINE = [:update, :append, :remove]

  def combine_results(a, b)
    KEYS_TO_COMBINE.each do |key|
      a[key] += b[key]
    end
  end

  def compact_compare_output(output, key:)
    result = { update: [], append: [], remove: [] }
    return result unless output.is_a?(Hash)

    KEYS_TO_COMBINE.each do |combine_key|
      output.fetch(combine_key, {}).each do |update_key, nested_output|
        new_key = "#{key}#{key.empty? ? '' : '.'}#{update_key}"
        result[combine_key] << new_key
        nested_result = compact_compare_output(nested_output, key: new_key)
        combine_results(result, nested_result)
      end
    end

    result
  end

  class JsonOutputCombiner
    def initialize(output)
      @output = output
    end

    def combine
      compact_compare_output(@output, key: "")
    end

    private

    KEYS_TO_COMBINE = [:update, :append, :remove]

    def combine_results(a, b)
      KEYS_TO_COMBINE.each do |key|
        a[key] += b[key]
      end
    end

    def compact_compare_output(output, key:)
      result = { update: [], append: [], remove: [] }
      return result unless output.is_a?(Hash)

      KEYS_TO_COMBINE.each do |combine_key|
        output.fetch(combine_key, {}).each do |update_key, nested_output|
          new_key = "#{key}#{key.empty? ? '' : '.'}#{update_key}"
          result[combine_key] << new_key
          nested_result = compact_compare_output(nested_output, key: new_key)
          combine_results(result, nested_result)
        end
      end

      result
    end
  end
end
