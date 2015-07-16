require 'spec_helper'

RSpec.describe RSpecRcv::Configuration do
  subject { RSpecRcv::Configuration.new }

  describe "exportable_proc" do
    it "is a proc by default" do
      expect(subject.exportable_proc).to be_a(Proc)
    end

    it "can be set" do
      subject.exportable_proc = "test"
      expect(subject.exportable_proc).to eq("test")
    end
  end

  describe "export_with" do
    it "uses to_json as the default export_with primarily for JS testing" do
      expect(subject.export_with).to eq(:to_json)
    end

    it "can be set" do
      subject.export_with = :to_yaml
      expect(subject.export_with).to eq(:to_yaml)
    end
  end

  describe "fail_on_changed_output" do
    it "is true for safer changes" do
      expect(subject.fail_on_changed_output).to eq(true)
    end

    it "can be set" do
      subject.fail_on_changed_output = false
      expect(subject.fail_on_changed_output).to eq(false)
    end
  end

  describe "base_path" do
    it "is nil to not make assumptions" do
      expect(subject.base_path).to eq(nil)
    end

    it "can be set" do
      subject.base_path = "test"
      expect(subject.base_path).to eq("test")
    end
  end

  describe ".reset!" do
    before(:each) {
      subject.base_path = "test"
      subject.fail_on_changed_output = false
      subject.export_with = :to_yaml
    }

    it "resets the settings to the defaults" do
      subject.reset!
      expect(subject.base_path).to eq(nil)
      expect(subject.fail_on_changed_output).to eq(true)
      expect(subject.export_with).to eq(:to_json)
    end
  end

  describe ".opts" do
    it "provides the opts" do
      expect(subject.opts).to be_a(Hash)
      expect(subject.opts[:base_path]).to eq(nil)
    end

    it "can be accept overrides" do
      override = { base_path: "test" }
      expect(subject.opts(override)[:base_path]).to eq("test")
    end
  end
end
