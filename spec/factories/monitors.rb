# frozen_string_literal: true

require 'ostruct'

module Sapristi
  # rubocop:disable Metrics/BlockLength:
  FactoryBot.define do
    # rubocop:enable Metrics/BlockLength:
    factory :monitor, class: Hash do
      data do
        { id: 0, name: 'some', main: '*', x: 3840, y: 2160, offset_x: 0, offset_y: 0,
          work_area: [0, 0, 3000, 2000],
          work_area_width: 3000, work_area_height: 2000 }.transform_keys(&:to_s)
      end

      initialize_with { data }
    end

    factory :work_area, class: OpenStruct do
      initialize_with do
        OpenStruct.new({ x: 100, y: 200, width: 300, height: 400 })
      end
    end

    factory :a_monitor, class: Hash do
      initialize_with do
        work_area = build(:work_area)
        work_area_width = work_area[:width]
        work_area_height = work_area[:height]
        { id: 0, name: 'a-monitor', main: '*', x: 1000, y: 2000, offset_x: 0, offset_y: 0,
          work_area: [work_area.x, work_area.y, work_area.x + work_area.width, work_area.y + work_area.height],
          work_area_width: work_area_width, work_area_height: work_area_height }.transform_keys(&:to_s)
      end
    end

    factory :another_monitor, class: Hash do
      initialize_with do
        work_area = build(:work_area)
        work_area_width = work_area[:width]
        work_area_height = work_area[:height]

        { id: 1, name: 'another-monitor', main: nil, x: 3000, y: 4000, offset_x: 0, offset_y: 0,
          work_area: [work_area.x, work_area.y, work_area.x + work_area.width, work_area.y + work_area.height],
          work_area_width: work_area_width, work_area_height: work_area_height }.transform_keys(&:to_s)
      end
    end

    factory :monitors, class: Array do
      initialize_with do
        [
          build(:a_monitor),
          build(:another_monitor)
        ]
      end
    end

    factory :xrandr_example, class: String do
      initialize_with do
        monitors = build(:monitors)
        lines = monitors.each_with_index.map do |monitor, index|
          main = monitor['main'] ? '*' : ''
          resolution = "#{monitor['x']}/123x#{monitor['y']}/456+#{monitor['offset_x']}+#{monitor['offset_y']}+0"
          "#{index}: +#{main}#{monitor['name']} #{resolution} #{monitor['name']}"
        end

        (["Monitors: #{monitors.size}"] + lines).join("\n")
      end
    end
  end
end
