# frozen_string_literal: true

require 'os'

module Sapristi
  class OSFactory
    def initialize
      @os = OS
    end

    def factory_module
      return Linux if linux?

      raise Error, "OS not implemented: #{os_name}"
    end

    def window_manager
      factory_module.const_get('WindowManager').new
    end

    def process_manager
      factory_module.const_get('ProcessManager')
    end

    def linux?
      @os.linux?
    end

    def os_name
      @os.parse_os_release[:pretty_name]
    end
  end
end
