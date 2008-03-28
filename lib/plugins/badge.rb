module WebApp
  module Plugins
    module Badge
      
      # Increases the badge counter on the applications dock icon unless the app is already visible.
      def increase_badge_counter!
        webViewController.objectCount += 1
        WebApp::Plugins::Badge.instance.increase_badge_counter!
      end
      
      class << self
        def included(klass)
          WebApp::Plugins.include_plugin(self)
        end
        
        def start
          @global_badge ||= GlobalBadge.alloc.init
        end
        
        def instance
          @global_badge
        end
      end
      
      class GlobalBadge < OSX::NSObject
        def init
          if super_init
            @ctbadge = OSX::CTBadge.alloc.init
            OSX::NSApp.delegate.counterDelegate = self
            self
          end
        end
        
        def total_count
          OSX::NSApp.delegate.webViewControllers.inject(0) { |sum, wvc| sum += wvc.objectCount }
        end
        
        def selected_items_count
          OSX::NSApp.delegate.tabBarController.tabView.selectedTabViewItem.webViewController.objectCount
        end
        
        def increase_badge_counter!
          if not OSX::NSApp.active? or Rucola::RCApp.debug?
            set_badge_value total_count
          end
        end
        
        def set_current_badge_value!
          set_badge_value total_count
        end
        
        def set_badge_value(value)
          if value.zero?
            OSX::NSApp.applicationIconImage = OSX::NSImage.imageNamed('NSApplicationIcon')
          else
            @ctbadge.badgeApplicationDockIconWithValue_insetX_y(value, 3, 0)
          end
        end
      end
    end
  end
end