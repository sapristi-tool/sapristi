# frozen_string_literal: true

module Sapristi
  # rubocop:disable Metrics/BlockLength:
  FactoryBot.define do
    # rubocop:enable Metrics/BlockLength:
    factory :valid_definition_hashes, class: Array do
      initialize_with do
        [
          {
            'Title' => nil, 'Command' => 'some', 'Monitor' => nil, 'X' => '1',
            'Y' => '2', 'Width' => '300', 'Height' => '400', 'Workspace' => '0',
            'Group' => nil
          },
          {
            'Title' => 'some title', 'Command' => nil, 'Monitor' => '6', 'X' => '7',
            'Y' => '8', 'Width' => '900', 'Height' => '100', 'Workspace' => '0',
            'Group' => nil
          },
          {
            'Title' => 'some title', 'Command' => nil, 'Monitor' => '0', 'X' => '10%',
            'Y' => '20%', 'Width' => '30%', 'Height' => '40%', 'Workspace' => nil,
            'Group' => nil
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
        x { '1' }
        y { '2' }
        width { '100' }
        height { '200' }
        workspace { '0' }
        group { nil }

        attrs { {} }

        default_attrs do
          {
            'Title' => title, 'Command' => command, 'Monitor' => monitor, 'X' => x,
            'Y' => y, 'Width' => width, 'Height' => height, 'Workspace' => workspace,
            'Group' => group
          }
        end
      end

      initialize_with do
        default_attrs.merge attrs
      end
    end
  end
end
