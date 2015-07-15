module RSpecRcv
  class Configuration
    def configure_rspec_metadata!
      unless @rspec_metadata_configured
        RSpecRcv::RSpec::Metadata.configure!
        @rspec_metadata_configured = true
      end
    end
  end
end
