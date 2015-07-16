require 'spec_helper'
require 'integration_helper'
require 'json'
require 'yaml'

RSpec.describe "Integration: Metadata w/ RSpec" do
  let(:prerecorded_time) { Time.now - 60*60 }

  def file_fixture(str, file: "test")
    {
        recorded_at: prerecorded_time,
        file: file,
        data: str
    }.to_json
  end

  before(:each) {
    File.delete("spec/integration/test.json") if File.exists?("spec/integration/test.json")
  }

  describe "writing out to disk" do
    it "writes the proper data and meta-data", rcv: { export_fixture_to: "spec/integration/test.json" } do
      def response
        double('Response', body: 'This is a test')
      end
    end

    around(:each) do |ex|
      ex.run
      output = JSON.parse(File.read("spec/integration/test.json"))
      File.delete("spec/integration/test.json")
      expect(output["data"]).to eq("This is a test")
      expect(Time.parse(output["recorded_at"])).to be_within(5).of(Time.now)
      expect(output["file"]).to eq("./spec/integration/metadata_spec.rb")
    end
  end

  describe "writing out to a sub-directory" do
    it "writes the proper data", rcv: { export_fixture_to: "spec/integration/tmp/deep/test.json" } do
      def response
        double('Response', body: 'This is a test')
      end
    end

    around(:each) do |ex|
      ex.run
      output = JSON.parse(File.read("spec/integration/tmp/deep/test.json"))
      FileUtils.rm_rf("spec/integration/tmp")
      expect(output["data"]).to eq("This is a test")
      expect(Time.parse(output["recorded_at"])).to be_within(5).of(Time.now)
      expect(output["file"]).to eq("./spec/integration/metadata_spec.rb")
    end
  end

  describe "with a base path" do
    it "writes to the correct location", rcv: { export_fixture_to: "test.json", base_path: "spec/integration" } do
      def response
        double('Response', body: 'This is a test')
      end
    end

    around(:each) do |ex|
      ex.run
      output = JSON.parse(File.read("spec/integration/test.json"))
      File.delete("spec/integration/test.json")
      expect(output["data"]).to eq("This is a test")
      expect(Time.parse(output["recorded_at"])).to be_within(5).of(Time.now)
      expect(output["file"]).to eq("./spec/integration/metadata_spec.rb")
    end
  end

  describe "with a custom proc" do
    it "uses the custom proc to export", rcv: { export_fixture_to: "spec/integration/test.json", exportable_proc: Proc.new{ custom }} do
      def custom
        'This is a test'
      end
    end

    around(:each) do |ex|
      ex.run
      output = JSON.parse(File.read("spec/integration/test.json"))
      File.delete("spec/integration/test.json")
      expect(output["data"]).to eq("This is a test")
      expect(Time.parse(output["recorded_at"])).to be_within(5).of(Time.now)
      expect(output["file"]).to eq("./spec/integration/metadata_spec.rb")
    end
  end

  describe "with a custom export_with" do
    it "writes the proper data and meta-data", rcv: { export_fixture_to: "spec/integration/test.json", export_with: :to_yaml } do
      def response
        double('Response', body: 'This is a test')
      end
    end

    around(:each) do |ex|
      ex.run
      output = YAML.load(File.read("spec/integration/test.json"))
      File.delete("spec/integration/test.json")
      expect(output[:data]).to eq("This is a test")
      expect(output[:recorded_at]).to be_within(5).of(Time.now)
      expect(output[:file]).to eq("./spec/integration/metadata_spec.rb")
    end
  end

  context "with an already existing file" do
    describe "that has identical data but a different file" do
      let(:fixture) { file_fixture("This is a test") }

      it "doesn't change the existing file", rcv: { export_fixture_to: "spec/integration/test.json" } do
        def response
          double('Response', body: 'This is a test')
        end
      end

      before(:each) {
        File.open("spec/integration/test.json", 'w') { |file| file.write(fixture) }
      }

      around(:each) do |ex|
        ex.run
        output = JSON.parse(File.read("spec/integration/test.json"))
        File.delete("spec/integration/test.json")
        expect(output["data"]).to eq("This is a test")
        expect(Time.parse(output["recorded_at"])).to be_within(5).of(Time.now)
        expect(output["file"]).to eq("./spec/integration/metadata_spec.rb")
      end
    end

    describe "that has identical data" do
      let(:fixture) { file_fixture("This is a test", file: "./spec/integration/metadata_spec.rb") }

      it "doesn't change the existing file", rcv: { export_fixture_to: "spec/integration/test.json" } do
        def response
          double('Response', body: 'This is a test')
        end
      end

      before(:each) {
        File.open("spec/integration/test.json", 'w') { |file| file.write(fixture) }
      }

      around(:each) do |ex|
        ex.run
        expect(File.read("spec/integration/test.json")).to eq(fixture)
        File.delete("spec/integration/test.json")
      end
    end

    describe "that has new contents" do
      let(:fixture) { file_fixture("This is different") }

      it "as a stub", rcv: { export_fixture_to: "spec/integration/test.json" } do
        def response
          double('Response', body: 'This is a test')
        end
      end

      before(:each) {
        File.open("spec/integration/test.json", 'w') { |file| file.write(fixture) }
      }

      around(:each) do |ex|
        ex.run
        expect(ex.exception).to be_a(RSpecRcv::DataChangedError)
        ex.example.display_exception = nil

        expect(File.read("spec/integration/test.json")).to eq(fixture)
        File.delete("spec/integration/test.json")
      end
    end

    describe "that has new contents but fail_on_changed_output = false" do
      let(:fixture) { file_fixture("This is different") }

      it "as a stub", rcv: { export_fixture_to: "spec/integration/test.json", fail_on_changed_output: false } do
        def response
          double('Response', body: 'This is a test')
        end
      end

      before(:each) {
        File.open("spec/integration/test.json", 'w') { |file| file.write(fixture) }
      }

      around(:each) do |ex|
        ex.run
        output = JSON.parse(File.read("spec/integration/test.json"))
        File.delete("spec/integration/test.json")
        expect(output["data"]).to eq("This is a test")
        expect(Time.parse(output["recorded_at"])).to be_within(5).of(Time.now)
        expect(output["file"]).to eq("./spec/integration/metadata_spec.rb")
      end
    end
  end
end
