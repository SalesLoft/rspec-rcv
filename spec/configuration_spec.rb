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

  describe "codecs" do
    it "uses pretty json as the default primarily for JS testing" do
      expect(subject.codec).to be_a(RSpecRcv::Codecs::PrettyJson)
    end

    it "can be set" do
      subject.codec = "x"
      expect(subject.codec).to eq("x")
    end
  end

  describe "ignore_keys" do
    it "is an empty array" do
      expect(subject.ignore_keys).to eq([])
    end

    it "can be set" do
      subject.ignore_keys = [:test]
      expect(subject.ignore_keys).to eq([:test])
    end
  end

  describe "compare_with" do
    it "ignores keys at the root level" do
      expect(subject.compare_with.call({a: 1}, {a: 2}, { ignore_keys: [] })).to eq(false)
      expect(subject.compare_with.call({a: 1}, {a: 2}, { ignore_keys: [:a] })).to eq(true)
    end

    it "doesn't ignore different keys" do
      expect(subject.compare_with.call({a: 1}, {a: 2}, { ignore_keys: [:b] })).to eq(false)
    end

    it "deep ignores the keys" do
      expect(subject.compare_with.call({deep: {a: 1}}, {deep: {a: 2}}, { ignore_keys: [] })).to eq(false)
      expect(subject.compare_with.call({deep: {a: 1}}, {deep: {a: 2}}, { ignore_keys: [:a] })).to eq(true)
    end

    it "can be set" do
      subject.compare_with = Proc.new { |e, n| false }
      expect(subject.compare_with.call(1, 1)).to eq(false)
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
      subject.codec = "test"
      subject.ignore_keys = [:test]
    }

    it "resets the settings to the defaults" do
      subject.reset!
      expect(subject.base_path).to eq(nil)
      expect(subject.fail_on_changed_output).to eq(true)
      expect(subject.codec).to be_a(RSpecRcv::Codecs::PrettyJson)
      expect(subject.ignore_keys).to eq([])
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
