# frozen_string_literal: true

module Sapristi
  # rubocop:disable Metrics/BlockLength:
  FactoryBot.define do
    # rubocop:enable Metrics/BlockLength:
    factory :valid_definition_hashes, class: Array do
      initialize_with do
        [
          {
            'Title' => nil, 'Command' => 'some', 'Monitor' => nil, 'X-position' => '1',
            'Y-position' => '2', 'H-size' => '300', 'V-size' => '400', 'Workspace' => '0'
          },
          {
            'Title' => 'some title', 'Command' => nil, 'Monitor' => '6', 'X-position' => '7',
            'Y-position' => '8', 'H-size' => '900', 'V-size' => '100', 'Workspace' => '0'
          },
          {
            'Title' => 'some title', 'Command' => nil, 'Monitor' => '0', 'X-position' => '10%',
            'Y-position' => '20%', 'H-size' => '30%', 'V-size' => '40%', 'Workspace' => nil
          }
        ]
      end
    end
    factory :valid_csv_definitions, class: Array do
      rows { build(:valid_definition_hashes) }

      initialize_with { rows.map { |definition| Definition.new definition } }
    end

    factory :a_valid_definition, class: Definition do
      transient do
        attrs { {} }
      end

      initialize_with do
        Definition.new(build(:valid_hash, attrs: attrs))
      end
    end

    factory :valid_hash, class: Hash do
      transient do
        title { 'some' }
        command { nil }
        monitor { nil }
        x_position { '1' }
        y_position { '2' }
        width { '100' }
        height { '200' }
        workspace { '0' }

        attrs { {} }

        default_attrs do
          {
            'Title' => title, 'Command' => command, 'Monitor' => monitor, 'X-position' => x_position,
            'Y-position' => y_position, 'H-size' => width, 'V-size' => height, 'Workspace' => workspace
          }
        end
      end

      initialize_with do
        default_attrs.merge attrs
      end
    end
  end
end
