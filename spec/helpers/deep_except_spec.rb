require 'spec_helper'
require 'json'

RSpec.describe RSpecRcv::Helpers::DeepExcept do
  subject { RSpecRcv::Helpers::DeepExcept.new(hash, except).to_h }

  context "with a simple hash" do
    let(:hash) { { "a" => 1, b: 2, c: 3 } }
    let(:except) { [:a, "b"] }

    it "ignores string and symbol keys" do
      expect(subject).to eq({c: 3})
    end

    context "with no except" do
      let(:except) { [] }

      it "ignores nothing" do
        expect(subject).to eq(hash)
      end
    end
  end

  context "with a nested hash" do
    let(:hash) {{
      "a" => 1,
      b: 2,
      c: 3,
      d: {
        a: 1,
        b: {
          nested_except: true
        },
        "c" => "safe"
      }
    }}

    let(:except) { [:a, "b"] }

    it "ignores nested keys" do
      expect(subject).to eq({
                              c: 3,
                              d: {
                                "c" => "safe"
                              }
                            })
    end

    context "nested in an array" do
      before(:each) do
        hash[:e] = [
          { a: 1 },
          { b: 2 },
          { c: 3 },
          { d: [
            [{ a: 1 }],
            { "c" => "safe" }
          ]}
        ]
      end

      it "ignores deeply nested keys in arrays" do
        expect(subject).to eq({
                                c: 3,
                                d: {
                                  "c" => "safe"
                                },
                                e: [
                                      {},
                                      {},
                                      { c: 3 },
                                      { d: [
                                            [{}],
                                            { "c" => "safe" }
                                           ]}
                                   ]
                              })
      end
    end
  end

  context "with an array" do
    let(:hash) {
      [
        [
          { a: 1, b: 2, c: 3},
          { a: 1 },
          { c: 3}
        ],
        { a: 1 },
        { c: 3 }
      ]
    }

    let(:except) { [:a, "b"] }

    it "ignores keys deeply nested in arrays" do
      expect(subject).to eq([
                              [
                                { c: 3 },
                                {},
                                { c: 3 }
                              ],
                              {},
                              { c: 3 }
                            ])
    end
  end
end

