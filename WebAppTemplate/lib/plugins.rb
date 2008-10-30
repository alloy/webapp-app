require 'set'

Dir.glob("#{File.expand_path("../plugins/", __FILE__)}/*.rb").each {|f| require f }

module WebApp
  module Plugins
    class << self
      def start
        included_plugins.each do |plugin|
          plugin.start
        end
      end
      
      def included_plugins
        @included_plugins ||= Set.new
      end
      
      def include_plugin(plugin)
        included_plugins << plugin
      end
    end
  end
  
  class EventHandler
    class << self
      # Loads a plugin. This is simply a shortcut for including a module.
      # Eg:
      #
      #   # shortcut:
      #   plugin :growl
      #
      #   # actually:
      #   include WebApp::Plugins::Growl
      def plugin(name, options = {})
        mod_name = name.to_s.camel_case
        if WebApp::Plugins.const_defined?(mod_name)
          mod = WebApp::Plugins.const_get(mod_name)
          include mod
          mod.plugin_arguments(self, options) if mod.respond_to?(:plugin_arguments)
          WebApp::Plugins.include_plugin(mod)
        else
          raise NameError, "The plugin module 'WebApp::Plugins::#{mod_name}' does not exist."
        end
      end
    end
  end
end