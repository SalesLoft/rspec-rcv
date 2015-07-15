require 'spec_helper'

RSpec.describe RSpecRcv::Runner do
  def initialize(context)
    @context = context
  end

  private

  attr_reader :context
end
