require 'diffy'

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
          raise_error!(output)
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

    def raise_error!(output)
      diff = Diffy::Diff.new(existing_file, output)
      removed = []
      added = []
      diff.to_s.each_line do |line|
        key = line.split("\"")[1]
        next if opts.fetch(:ignore_keys, []).include?(key)
        next if key.nil?

        if line.start_with?("-")
          removed << key
        elsif line.start_with?("+")
          added << key
        end
      end

      raise RSpecRcv::DataChangedError.new(<<-EOF)
Existing data will be overwritten. Turn off this feature with fail_on_changed_output=false

#{diff}

The following keys were added: #{added.uniq}
The following keys were removed: #{removed.uniq}
      EOF
    end
  end
end
