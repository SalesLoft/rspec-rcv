require 'spec_helper'
require 'integration_helper'

RSpec.describe "Basic integration RSpec test" do
  before(:each) {
    File.delete("spec/integration/test.json") if File.exists?("spec/integration/test.json")
  }

  describe "writing out to disk" do
    it "as a stub", rcv: { export_fixture_to: "spec/integration/test.json" } do
      def response
        double('Response', body: 'This is a test')
      end
    end

    around(:each) do |ex|
      ex.run
      expect(File.read("spec/integration/test.json")).to eq("This is a test")
      File.delete("spec/integration/test.json")
    end
  end

  describe "with a base path" do
    it "as a stub", rcv: { export_fixture_to: "test.json", base_path: "spec/integration" } do
      def response
        double('Response', body: 'This is a test')
      end
    end

    around(:each) do |ex|
      ex.run
      expect(File.read("spec/integration/test.json")).to eq("This is a test")
      File.delete("spec/integration/test.json")
    end
  end

  describe "with a custom proc" do
    it "as a stub", rcv: { export_fixture_to: "spec/integration/test.json", exportable_proc: Proc.new{ custom }} do
      def custom
        'This is a test'
      end
    end

    around(:each) do |ex|
      ex.run
      expect(File.read("spec/integration/test.json")).to eq("This is a test")
      File.delete("spec/integration/test.json")
    end
  end

  context "with an already existing file" do
    describe "that has identical contents" do
      it "as a stub", rcv: { export_fixture_to: "spec/integration/test.json" } do
        def response
          double('Response', body: 'This is a test')
        end
      end

      before(:each) {
        File.open("spec/integration/test.json", 'w') { |file| file.write("This is a test") }
      }

      around(:each) do |ex|
        ex.run
        expect(File.read("spec/integration/test.json")).to eq("This is a test")
        File.delete("spec/integration/test.json")
      end
    end

    describe "that has new contents" do
      it "as a stub", rcv: { export_fixture_to: "spec/integration/test.json" } do
        def response
          double('Response', body: 'This is a test')
        end
      end

      before(:each) {
        File.open("spec/integration/test.json", 'w') { |file| file.write("This is different") }
      }

      around(:each) do |ex|
        ex.run
        expect(ex.exception).to be_a(RSpecRcv::DataChangedError)
        ex.example.display_exception = nil
        expect(File.read("spec/integration/test.json")).to eq("This is different")
        File.delete("spec/integration/test.json")
      end
    end

    describe "that has new contents but fail_on_changed_output = false" do
      it "as a stub", rcv: { export_fixture_to: "spec/integration/test.json", fail_on_changed_output: false } do
        def response
          double('Response', body: 'This is a test')
        end
      end

      before(:each) {
        File.open("spec/integration/test.json", 'w') { |file| file.write("This is different") }
      }

      around(:each) do |ex|
        ex.run
        expect(File.read("spec/integration/test.json")).to eq("This is a test")
        File.delete("spec/integration/test.json")
      end
    end
  end
end
