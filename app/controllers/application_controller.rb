$WEBAPP_DEBUG = true

class ApplicationController < Rucola::RCController
  ib_outlet :main_window
  ib_outlet :tabView
  ib_outlet :tabBarController
  ib_outlet :bundlesMenu
  
  attr_reader :webViewControllers
  attr_accessor :counterDelegate
  
  def awakeFromNib
    OSX::NSApp.delegate = self
    
    # Make sure that SRAutoFillManager stores/retrieves usernames & passwords.
    OSX::NSUserDefaults.standardUserDefaults.registerDefaults({
      'autoFillUserPass' => true
    })
    
    @main_window.title = OSX::NSBundle.mainBundle.infoDictionary['WebAppURL'].to_s.scan(/https*:\/\/(.*?)\/*$/)[0][0]
    
    setup_tabView!
    setup_tabBarController!
    
    @bundle_window_controllers = {}
    
    ["#{Rucola::RCApp.root_path}/bundles/", Rucola::RCApp.application_support_path].each do |bundles|
      # Load all event handlers
      Dir.glob("#{bundles}/*.wabundle/event_handlers/*.rb").each do |event_handler|
        require event_handler
      end
      
      # Load all window controllers
      Dir.glob("#{bundles}/*.wabundle/controllers/*.rb").each do |controller|
        require controller
        klass = File.constantize(controller)
        
        item = OSX::NSMenuItem.alloc.initWithTitle_action_keyEquivalent("#{klass.name.scan(/([A-Z][a-z]+)/).flatten[0..-2].join(' ')}...", 'openBundleWindowController:', '')
        item.target = self
        item.representedObject = klass
        
        @bundlesMenu.addItem(item)
      end
    end
    
    # If there are any custom user css rules, now is the time to write them out.
    if stylesheet_path = WebApp::EventHandler.write_tmp_stylesheet!
      # And assign it to the WebView preferences.
      prefs = OSX::WebPreferences.standardPreferences
      prefs.userStyleSheetEnabled = true
      prefs.userStyleSheetLocation = OSX::NSURL.fileURLWithPath(stylesheet_path)
    end
    
    @webViewControllers = []
    addWebViewTab
  end
  
  def openBundleWindowController(menuItem)
    (@bundle_window_controllers[menuItem.representedObject] ||= menuItem.representedObject.alloc.init).showWindow(self)
  end
  
  def addWebViewTab(url = nil)
    if url.is_a? OSX::NSURL
      @webViewControllers << WebViewController.alloc.initWithURL(url)
    else
      @webViewControllers << WebViewController.alloc.init
    end
    @tabView.addTabViewItem @webViewControllers.last.tabViewItem
    WebApp::Plugins.start
  end
  
  def applicationDidBecomeActive(notification)
    @tabView.selectedTabViewItem.webViewController.objectCount = 0
    @counterDelegate.set_current_badge_value! if @counterDelegate
  end
  
  def tabView_didSelectTabViewItem(tabView, tabViewItem)
    tabViewItem.webViewController.objectCount = 0
    @counterDelegate.set_current_badge_value! if @counterDelegate
  end
  
  def removeWebViewTab(tabViewItem)
    @tabView.removeTabViewItem(tabViewItem)
    tabView_didCloseTabViewItem(@tabView, tabViewItem)
  end
  
  def tabView_didCloseTabViewItem(tabView, tabViewItem)
    @webViewControllers.reject! { |wvc| wvc.tabViewItem == tabViewItem }
  end
  
  private
  
  def setup_tabView!
    @tabView.removeTabViewItem(@tabView.tabViewItemAtIndex(0))
    @tabView.delegate = @tabBarController
  end
  
  def setup_tabBarController!
    @tabBarController.tabView = @tabView
    @tabBarController.setStyleNamed('Unified')
    @tabBarController.delegate = self
    @tabBarController.showAddTabButton = true
    button = @tabBarController.addTabButton
    button.target = self
    button.action = :addWebViewTab
  end
end