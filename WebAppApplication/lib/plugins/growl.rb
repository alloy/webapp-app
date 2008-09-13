module WebApp
  module Plugins
    module Growl
      
      def growl(name, title, description, options = {}, &callback)
        if !OSX::NSApp.active? || Rucola::RCApp.debug?
          callback = callback || @bring_app_and_tab_to_the_front
          ::Growl::Notifier.sharedInstance.notify(name, title, description, options, &callback)
        end
      end
      
      # Sends a sticky Growl notification. See Growl::Notifier#notify for more info.
      def sticky_growl(name, title, description, options = {}, &callback)
        growl(name, title, description, options.merge!(:sticky => true), &callback)
      end
      
      # STill need to do this one:
      #     if block.nil?
      #       block_object_id = @bring_app_and_tab_to_the_front.object_id
      #       register_callback(@bring_app_and_tab_to_the_front)
      #     else
      
      class << self
        def registered_notifications
          @registered_notifications ||= {}
        end
        
        def notification_names
          @notification_names ||= Set.new
        end
        
        def plugin_arguments(klass, notifications)
          registered_notifications[klass] = notifications
          notifications.each_value { |name| notification_names << name }
        end
        
        def start
          registered_notifications.each do |klass, notifications|
            notifications.each do |method, name|
              klass.class_eval %{
                def growl_#{method}(title, description, &block)
                  growl('#{name}', title, description, &block)
                end
                
                def sticky_growl_#{method}(title, description, &block)
                  sticky_growl('#{name}', title, description, &block)
                end
              }
            end
          end
          
          ::Growl::Notifier.sharedInstance.register(Rucola::RCApp.app_name.to_sym, notification_names.to_a)
        end
      end
    end
  end
end