$WEBAPP_DEBUG = false

module WebApp
  module Plugins
    class << self
      def start
        included_plugins.each do |plugin|
          plugin.start
        end
      end
      
      def included_plugins
        @included_plugins ||= []
      end
      
      def include_plugin(plugin)
        included_plugins << plugin unless included_plugins.include?(plugin)
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
        else
          raise NameError, "The plugin module 'WebApp::Plugins::#{mod_name}' does not exist."
        end
      end
    end
  end
end

module WebApp
  module Plugins
    module Growl
      
      # This is the method that will make you growl!
      def growl(type, title, description)
        WebApp::Plugins::Growl.instance.notify(type, title, description) if $WEBAPP_DEBUG or not OSX::NSApp.active?
      end
      
      class << self
        def included(klass)
          WebApp::Plugins.include_plugin(self)
        end
        
        # After including the module any arguments passed to #plugin other than the name will be passed to this method together with the class that passed these args.
        def plugin_arguments(klass, options)
          (@registered_notifications ||= {})[klass] = options
        end
        
        def start
          @registered_notifications.each do |klass, notifications|
            klass.class_eval do
              notifications.each do |mname, name|
                # define the shortcut method: #growl_foo(title, description)
                growl_mname = "growl_#{mname}".to_sym
                define_method(growl_mname) do |title, description|
                  growl(name, title, description)
                end
              end
            end
          end
          
           # get an array of all the registered notifications.
          notification_names = []
          @registered_notifications.values.each do |v|
            notification_names << v.values
          end
          notification_names.flatten!
          
          @growl_bridge = GrowlBridge.alloc.initWithDelegate(self)
          @growl_bridge.start(:Campfire, notification_names, notification_names)
        end
        
        def instance
          @growl_bridge
        end
      end
      
      # Created by Satoshi Nakagawa.
      # You can redistribute it and/or modify it under the Ruby's license or the GPL2.
      class GrowlBridge < OSX::NSObject
        #include OSX
        attr_accessor :delegate

        GROWL_IS_READY = "Lend Me Some Sugar; I Am Your Neighbor!"
        GROWL_NOTIFICATION_CLICKED = "GrowlClicked!"
        GROWL_NOTIFICATION_TIMED_OUT = "GrowlTimedOut!"
        GROWL_KEY_CLICKED_CONTEXT = "ClickedContext"

        def initWithDelegate(delegate)
          init
          @delegate = delegate
          self
        end

        def start(appname, notifications, default_notifications=nil, appicon=nil)
          @appname = appname
          @notifications = notifications
          @default_notifications = default_notifications
          @appicon = appicon
          @default_notifications = @notifications unless @default_notifications
          register
        end

        def notify(type, title, desc, click_context=nil, sticky=false, priority=0, icon=nil)
          dic = {
            :ApplicationName => @appname,
            :ApplicationPID => OSX::NSProcessInfo.processInfo.processIdentifier,
            :NotificationName => type,
            :NotificationTitle => title,
            :NotificationDescription => desc,
            :NotificationPriority => priority,
          }
          dic[:NotificationIcon] = icon.TIFFRepresentation if icon
          dic[:NotificationSticky] = 1 if sticky
          dic[:NotificationClickContext] = click_context if click_context

          c = OSX::NSDistributedNotificationCenter.defaultCenter
          c.postNotificationName_object_userInfo_deliverImmediately(:GrowlNotification, nil, dic, true)
        end

        KEY_TABLE = {
          :type => :NotificationName,
          :title => :NotificationTitle,
          :desc => :NotificationDescription,
          :clickContext => :NotificationClickContext,
          :sticky => :NotificationSticky,
          :priority => :NotificationPriority,
          :icon => :NotificationIcon,
        }

        def notifyWith(hash)
          dic = {}
          KEY_TABLE.each {|k,v| dic[v] = hash[k] if hash.key?(k) }
          dic[:ApplicationName] = @appname
          dic[:ApplicationPID] = NSProcessInfo.processInfo.processIdentifier

          c = OSX::NSDistributedNotificationCenter.defaultCenter
          c.postNotificationName_object_userInfo_deliverImmediately(:GrowlNotification, nil, dic, true)
        end

        def onReady(n)
          register
        end

        def onClicked(n)
          context = n.userInfo[GROWL_KEY_CLICKED_CONTEXT].to_s
          @delegate.growl_onClicked(self, context) if @delegate && @delegate.respond_to?(:growl_onClicked)
        end

        def onTimeout(n)
          context = n.userInfo[GROWL_KEY_CLICKED_CONTEXT].to_s
          @delegate.growl_onTimeout(self, context) if @delegate && @delegate.respond_to?(:growl_onTimeout)
        end

        private

        def register
          pid = OSX::NSProcessInfo.processInfo.processIdentifier.to_i

          c = OSX::NSDistributedNotificationCenter.defaultCenter
          c.addObserver_selector_name_object(self, 'onReady:', GROWL_IS_READY, nil)
          c.addObserver_selector_name_object(self, 'onClicked:', "#{@appname}-#{pid}-#{GROWL_NOTIFICATION_CLICKED}", nil)
          c.addObserver_selector_name_object(self, 'onTimeout:', "#{@appname}-#{pid}-#{GROWL_NOTIFICATION_TIMED_OUT}", nil)

          icon = @appicon || OSX::NSApplication.sharedApplication.applicationIconImage
          dic = {
            :ApplicationName => @appname,
            :AllNotifications => @notifications,
            :DefaultNotifications => @default_notifications,
            :ApplicationIcon => icon.TIFFRepresentation,
          }
          c.postNotificationName_object_userInfo_deliverImmediately(:GrowlApplicationRegistrationNotification, nil, dic, true)
        end
      end
    end
  end
end

module WebApp
  module Plugins
    module Badge
      
      # Increases the badge counter on the applications dock icon unless the app is already visible.
      def increase_badge_counter!
        # TODO: also keep a counter here, so later on when we have tabs we can keep a count per tab.
        # (@badge_counter ||= 0) += 1
        WebApp::Plugins::Badge.instance.increase_badge_counter!
      end
      
      class << self
        def included(klass)
          WebApp::Plugins.include_plugin(self)
        end
        
        def start
          @global_badge = GlobalBadge.alloc.init
        end
        
        def instance
          @global_badge
        end
      end
      
      class GlobalBadge < OSX::NSObject
        def init
          if super_init
            @badge_counter = 0
            @ctbadge = OSX::CTBadge.alloc.init
            
            OSX::NSNotificationCenter.defaultCenter.objc_send(
              :addObserver, self,
                 :selector, :applicationDidBecomeActive,
                     :name, OSX::NSApplicationDidBecomeActiveNotification,
                   :object, nil
            )
            
            self
          end
        end
        
        def increase_badge_counter!
          if $WEBAPP_DEBUG or not OSX::NSApp.active?
            @badge_counter += 1
            set_badge_value!
          end
        end
        
        def applicationDidBecomeActive(notification)
          @badge_counter = 0
          set_badge_value!
        end
        
        def set_badge_value!
          if @badge_counter.zero?
            OSX::NSApp.applicationIconImage = OSX::NSImage.imageNamed('NSApplicationIcon')
          else
            @ctbadge.badgeApplicationDockIconWithValue_insetX_y(@badge_counter, 3, 0)
          end
        end
      end
    end
  end
end