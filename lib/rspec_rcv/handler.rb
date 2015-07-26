require 'diffy'

module RSpecRcv
  class Handler
    def initialize(file_path, data, metadata: {})
      @file_path = file_path
      @opts = RSpecRcv.config(metadata)
      @data = data.call(@opts)
    end

    def call
      return if existing_data && existing_data["file"] == file_path && existing_data["data"] == data

      output = { recorded_at: Time.now, file: file_path, data: data }
      output = opts[:codec].export_with(output) + "\n"

      if existing_data
        eq = opts[:compare_with].call(existing_data["data"], data)

        if !eq && opts[:fail_on_changed_output]
          diff = Diffy::Diff.new(existing_file, output)
          raise RSpecRcv::DataChangedError.new("Existing data will be overwritten. Turn off this feature with fail_on_changed_output=false\n\n#{diff}")
        end

        return if eq
      end

      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') do |file|
        file.write(output)
      end
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
  end
end
