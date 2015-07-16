module RSpecRcv
  class Handler
    def initialize(file_path, data, metadata: {})
      @file_path = file_path
      @opts = RSpecRcv.config(metadata)
      @data = data.call(@opts)
    end

    def call
      return if existing_data && existing_data["file"] == file_path && existing_data["data"] == data

      if existing_data && opts[:fail_on_changed_output]
        if existing_data["data"] != data
          raise RSpecRcv::DataChangedError.new("Existing data will be overwritten. Turn off this feature with fail_on_changed_output=false")
        end
      end

      FileUtils.mkdir_p(File.dirname(path))
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
end
