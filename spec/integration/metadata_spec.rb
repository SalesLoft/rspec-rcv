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
    it "writes the proper data and meta-data", rcv: { fixture: "spec/integration/test.json" } do
      def response
        double('Response', body: {a: 1}.to_json)
      end
    end

    around(:each) do |ex|
      ex.run
      output = JSON.parse(File.read("spec/integration/test.json"))
      File.delete("spec/integration/test.json")
      expect(output["data"]).to eq({"a" => 1})
      expect(Time.parse(output["recorded_at"])).to be_within(5).of(Time.now)
      expect(output["file"]).to eq("./spec/integration/metadata_spec.rb")
    end
  end

  describe "writing out to a sub-directory" do
    it "writes the proper data", rcv: { fixture: "spec/integration/tmp/deep/test.json" } do
      def response
        double('Response', body: {a: 1}.to_json)
      end
    end

    around(:each) do |ex|
      ex.run
      output = JSON.parse(File.read("spec/integration/tmp/deep/test.json"))
      FileUtils.rm_rf("spec/integration/tmp")
      expect(output["data"]).to eq({"a" => 1})
      expect(Time.parse(output["recorded_at"])).to be_within(5).of(Time.now)
      expect(output["file"]).to eq("./spec/integration/metadata_spec.rb")
    end
  end

  describe "with a base path" do
    it "writes to the correct location", rcv: { fixture: "test.json", base_path: "spec/integration" } do
      def response
        double('Response', body: {a: 1}.to_json)
      end
    end

    around(:each) do |ex|
      ex.run
      output = JSON.parse(File.read("spec/integration/test.json"))
      File.delete("spec/integration/test.json")
      expect(output["data"]).to eq({"a" => 1})
      expect(Time.parse(output["recorded_at"])).to be_within(5).of(Time.now)
      expect(output["file"]).to eq("./spec/integration/metadata_spec.rb")
    end
  end

  describe "with a custom proc" do
    it "uses the custom proc to export", rcv: { fixture: "spec/integration/test.json", exportable_proc: Proc.new{ custom }} do
      def custom
        {a: 1} # Return an object for the Codec
      end
    end

    around(:each) do |ex|
      ex.run
      output = JSON.parse(File.read("spec/integration/test.json"))
      File.delete("spec/integration/test.json")
      expect(output["data"]).to eq({"a" => 1})
      expect(Time.parse(output["recorded_at"])).to be_within(5).of(Time.now)
      expect(output["file"]).to eq("./spec/integration/metadata_spec.rb")
    end
  end

  describe "with a custom codec" do
    it "writes the proper data and meta-data", rcv: { fixture: "spec/integration/test.json", codec: RSpecRcv::Codecs::Yaml.new } do
      def response
        double('Response', body: { a: 1 }.to_json)
      end
    end

    around(:each) do |ex|
      ex.run
      output = YAML.load(File.read("spec/integration/test.json"))
      File.delete("spec/integration/test.json")
      expect(output[:data]).to eq({"a" => 1})
      expect(output[:recorded_at]).to be_within(5).of(Time.now)
      expect(output[:file]).to eq("./spec/integration/metadata_spec.rb")
    end
  end

  context "with an already existing file" do
    describe "that has identical data but a different file" do
      let(:fixture) { file_fixture({a: 1}) }

      it "doesn't change the existing file", rcv: { fixture: "spec/integration/test.json" } do
        def response
          double('Response', body: {a: 1}.to_json)
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

    describe "that has identical data" do
      let(:fixture) { file_fixture({a: 1}, file: "./spec/integration/metadata_spec.rb") }

      it "doesn't change the existing file", rcv: { fixture: "spec/integration/test.json" } do
        def response
          double('Response', body: {a: 1}.to_json)
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

    describe "that has different data but compare_with is true" do
      let(:fixture) { file_fixture({a: 2}, file: "./spec/integration/metadata_spec.rb") }

      it "doesn't change the existing file", rcv: { fixture: "spec/integration/test.json", compare_with: lambda {|e, n, opts| true } } do
        def response
          double('Response', body: {a: 1}.to_json)
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
      let(:fixture) { file_fixture({a: 1, deep: { a: 2, b: 3 }}) }

      it "raises a DataChangedError", rcv: { fixture: "spec/integration/test.json" } do
        def response
          double('Response', body: {a: 1}.to_json)
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

    describe "that has new contents in ignored keys" do
      let(:fixture) { file_fixture({a: 1, deep: { a: 2, b: 3 }}) }

      it "doesn't change the existing file", rcv: { fixture: "spec/integration/test.json", ignore_keys: [:a] } do
        def response
          double('Response', body: {a: 1, deep: { a: 3, b: 3 }}.to_json)
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

    describe "that has new contents but fail_on_changed_output = false" do
      let(:fixture) { file_fixture({a: 2}) }

      it "updates the file silently", rcv: { fixture: "spec/integration/test.json", fail_on_changed_output: false } do
        def response
          double('Response', body: {a: 1}.to_json)
        end
      end

      before(:each) {
        File.open("spec/integration/test.json", 'w') { |file| file.write(fixture) }
      }

      around(:each) do |ex|
        ex.run
        output = JSON.parse(File.read("spec/integration/test.json"))
        File.delete("spec/integration/test.json")
        expect(output["data"]).to eq({"a" => 1})
        expect(Time.parse(output["recorded_at"])).to be_within(5).of(Time.now)
        expect(output["file"]).to eq("./spec/integration/metadata_spec.rb")
      end
    end
  end
end
