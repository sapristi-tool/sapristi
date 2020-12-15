# frozen_string_literal: true

module Sapristi
  class Monitor
    def initialize(data)
      data.each { |key, value| instance_variable_set "@#{key}".to_sym, value }
    end

    def [](key)
      instance_variable_get "@#{key}"
    end

    ATTRIBUTES = %i[id main name x y offset_x offset_y work_area work_area_width work_area_height].freeze

    attr_reader(*ATTRIBUTES)

    def hash
      state.hash
    end

    def ==(other)
      other.class == self.class && state == other.state
    end

    alias eql? ==

    protected

    def state
      ATTRIBUTES.map { |attribute| send attribute }
    end
  end
end
