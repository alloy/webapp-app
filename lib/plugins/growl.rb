module WebApp
  module Plugins
    module Growl
      
      # This is the method that will make you growl!
      def growl(type, title, description, sticky = false)
        WebApp::Plugins::Growl.instance.notify(type, title, description, 'WebAppBringToFront', sticky) if not OSX::NSApp.active? or $WEBAPP_DEBUG
      end
      
      # FIXME: Why doesn't the window get key and order front...
      BRING_TO_FRONT = Proc.new { OSX::NSApp.activateIgnoringOtherApps(true) }
      
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
                
                # define the shortcut method: #sticky_growl_foo(title, description)
                growl_mname = "sticky_growl_#{mname}".to_sym
                define_method(growl_mname) do |title, description|
                  growl(name, title, description, true)
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
        
        def growl_onClicked(sender, context)
          puts "Growl notification clicked: #{context}" if $WEBAPP_DEBUG
          WebApp::Plugins::Growl::BRING_TO_FRONT.call
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
