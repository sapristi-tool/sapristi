# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  RSpec.describe Definition do
    it 'two definitions with same attributes are equal' do
      attributes = build(:valid_hash)
      expect(Definition.new(attributes)).to eq(Definition.new(attributes))
    end
  end
end
