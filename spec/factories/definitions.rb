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

    factory :monitor, class: Hash do
      data do
        { id: 0, name: 'some', main: '*', x: 3840, y: 2160, offset_x: 0, offset_y: 0 }.transform_keys(&:to_s)
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
