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
          if not OSX::NSApp.active? or $WEBAPP_DEBUG
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