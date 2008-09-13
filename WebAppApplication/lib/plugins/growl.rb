module WebApp
  module Plugins
    module Growl
      
      def growl(name, title, description, options = {}, &callback)
        if !OSX::NSApp.active? || Rucola::RCApp.debug?
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
      
      # class << self
      #   # After including the module any arguments passed to #plugin other than the name will be passed to this method together with the class that passed these args.
      #   def plugin_arguments(klass, options)
      #     (@registered_notifications ||= {})[klass] = options
      #   end
      #   
      #   def start
      #     @registered_notifications.each do |klass, notifications|
      #       str = "class #{klass.name}\n\n"
      #       notifications.each do |mname, name|
      #         str += %{
      #           def growl_#{mname}(title, description, &block)
      #             if block_given?
      #               growl("#{name}", title, description, false, block)
      #             else
      #               growl("#{name}", title, description)
      #             end
      #           end
      #           
      #           def sticky_growl_#{mname}(title, description, &block)
      #             if block_given?
      #               growl("#{name}", title, description, true, block)
      #             else
      #               growl("#{name}", title, description, true)
      #             end
      #           end
      #         }
      #       end
      #       str += "\n\nend"
      #       eval str
      #     end
      #     
      #      # get an array of all the registered notifications.
      #     notification_names = []
      #     @registered_notifications.values.each do |v|
      #       notification_names << v.values
      #     end
      #     notification_names.flatten!
      #     
      #     if @growl_bridge.nil?
      #       @growl_bridge = GrowlBridge.sharedInstance
      #       @growl_bridge.delegate = self
      #       # FIXME: hardcoded the application name.
      #       @growl_bridge.start(:Campfire, notification_names, notification_names)
      #     end
      #   end
      #   
      #   def instance
      #     @growl_bridge
      #   end
      #   
      #   def callbacks
      #     @callbacks ||= {}
      #   end
      #   
      #   def growl_onClicked(sender, context)
      #     log.debug "Growl notification clicked: #{context}"
      #     OSX::NSNotificationCenter.defaultCenter.postNotificationName_object('WebAppCallbackNotification', context)
      #   end
      # end
    end
  end
end