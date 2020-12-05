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
        ].map { |definition| Definition.new definition }
      end

      initialize_with { rows }
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
        x_position { 1 }
        y_position { 2 }
        width { 100 }
        height { 200 }
        workspace { 0 }

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

    factory :monitor, class: Hash do
      data do
        { id: 0, name: 'some', main: '*', x: 3840, y: 2160, offset_x: 0, offset_y: 0,
          work_area: [0, 0, 3000, 2000],
          work_area_width: 3000, work_area_height: 2000 }.transform_keys(&:to_s)
      end

      initialize_with { data }
    end

    factory :xrandr_example, class: String do
      initialize_with do
        %(Monitors: 2
   0: +*some 3840/597x2160/336+0+0  DP-1
   1: +another 1920/509x1080/286+3840+0  HDMI-1)
      end
    end
  end
end
