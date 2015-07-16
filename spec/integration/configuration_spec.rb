require 'spec_helper'

RSpecRcv.configure do |config|
  config.configure_rspec_metadata!
  config.exportable_proc = Proc.new { custom }
end

RSpec.describe "Integration: Configuration w/ RSpec" do
  describe "with a custom proc" do
    it "uses the custom proc to export", rcv: { fixture: "spec/integration/test.json" } do
      def custom
        'This is a test'
      end
    end

    around(:each) do |ex|
      ex.run
      output = JSON.parse(File.read("spec/integration/test.json"))
      File.delete("spec/integration/test.json")
      RSpecRcv.configuration.reset!
      expect(output["data"]).to eq("This is a test")
      expect(Time.parse(output["recorded_at"])).to be_within(5).of(Time.now)
      expect(output["file"]).to eq("./spec/integration/configuration_spec.rb")
    end
  end
end
