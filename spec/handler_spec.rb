require 'spec_helper'

RSpec.describe RSpecRcv::Handler do
  let!(:data) { Proc.new { { "key" => "value" } } } # Hash rocket syntax because JSON read from disk is string=>string
  let!(:file_path) { "spec/tmp/test.json" }
  let!(:metadata) { { fixture: file_path } }
  let(:parsed_json) { JSON.parse(File.read(file_path)) }

  subject { RSpecRcv::Handler.new("spec/handler_spec.rb", data, metadata: metadata) }

  after(:each) { FileUtils.rm_rf("spec/tmp") }

  context "without an existing file" do
    it "creates a new file" do
      expect {
        expect(subject.call).to eq(:to_disk)
      }.to change{ File.exists?(file_path) }.from(false).to(true)
    end

    it "puts the correct fields on disk" do
      subject.call
      expect(parsed_json.keys).to eq(["recorded_at", "file", "data"])
      expect(Time.parse(parsed_json["recorded_at"])).to be_within(2).of(Time.now)
      expect(parsed_json["file"]).to eq("spec/handler_spec.rb")
      expect(parsed_json["data"]).to eq({ "key" => "value"})
    end
  end

  context "with an existing file" do
    let!(:other_data) { Proc.new { { "key" => "value" } }}
    before(:each) {
      RSpecRcv::Handler.new("spec/handler_spec.rb", other_data, metadata: metadata).call
    }

    context "that has the same data" do
      it "doesn't do anything" do
        expect(subject.call).to eq(:no_change)
      end
    end

    context "that has different data" do
      let!(:other_data) { Proc.new { { "other" => "value" } }}

      it "raises RSpecRcv::DataChangedError" do
        expect {
          subject.call
        }.to raise_error(RSpecRcv::DataChangedError)
      end

      context "when fail_on_changed_output=false" do
        let!(:metadata) { { fixture: file_path, fail_on_changed_output: false } }

        it "doesn't raise an error" do
          expect {
            subject.call
          }.not_to raise_error
        end

        it "writes to disk" do
          expect {
            expect(subject.call).to eq(:to_disk)
          }.to change{ File.read(file_path) }

          expect(parsed_json["data"]).to eq({ "key" => "value" })
        end
      end
    end
  end
end
