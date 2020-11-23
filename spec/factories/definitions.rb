# frozen_string_literal: true

module Sapristi
  FactoryBot.define do
    factory :valid_csv_definitions, class: Array do
      rows do
        [
          {
            'Title' => nil, 'Command' => 'some', 'Monitor' => nil, 'X-position' => 1,
            'Y-position' => 2, 'H-size' => 300, 'V-size' => 400, 'Workspace' => 0
          },
          {
            'Title' => 'some title', 'Command' => nil, 'Monitor' => 6, 'X-position' => 7,
            'Y-position' => 8, 'H-size' => 900, 'V-size' => 100, 'Workspace' => 0
          },
          {
            'Title' => 'some title', 'Command' => nil, 'Monitor' => 0, 'X-position' => '10%',
            'Y-position' => '20%', 'H-size' => '30%', 'V-size' => '40%', 'Workspace' => nil
          }
        ]
      end

      initialize_with { rows }
    end
  end
end
