# frozen_string_literal: true

module Sapristi
  RSpec.shared_examples 'percentage in field' do |field|
    it "apply percentage in #{field}" do
      translations = Definition::TRANSLATIONS

      percentage = valid_csv_definitions[2].to_h[field].match(/^([0-9]+)%$/)[1].to_i
      expected = ((percentage / 100.0) * monitor[translations[field]]).to_i
      expect(content[2][field]).to be expected
    end
  end

  RSpec.shared_examples 'geometry percentage' do |field, min_percentage = 5|
    it "when #{field} percentage x < #{min_percentage}" do
      if min_percentage.positive?
        raw = "#{min_percentage - 1}%"
        definition_attrs = build(:valid_hash, attrs: { field => raw })
        expect { subject.parse definition_attrs }
          .to raise_error(Error, /#{field} percentage is invalid=#{raw}, valid=#{min_percentage}%-100%/)
      end
    end
  end
end
