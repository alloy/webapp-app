class ApplicationController < Rucola::RCController
  ib_outlet :main_window
  ib_outlet :tabView
  ib_outlet :tabBarController
  ib_outlet :bundlesMenu
  
  attr_reader :webViewControllers
  attr_accessor :counterDelegate
  
  def awakeFromNib
    OSX::NSApp.delegate = self
    @main_window.title = OSX::NSBundle.mainBundle.infoDictionary['WebAppURL'].to_s.scan(/https*:\/\/(.*?)\/*$/)[0][0]
    
    registerDefaults
    setupTabBarController
    loadBundles
    writeUserStyleSheet
    addWebViewTab
    
    WebApp::Plugins.start
    
    # app_name = OSX::NSBundle.mainBundle.infoDictionary['WebAppName']
    # items = OSX::NSApp.mainMenu.itemAtIndex(0).submenu.itemArray
    # items.first.title = "About #{app_name}"
    # items.last.title = "Quit #{app_name}"
    # items.find { |i| i.title == "Hide NewApplication" }.title = "Hide #{app_name}"
  end
  
  def openBundleWindowController(menuItem)
    (@bundle_window_controllers[menuItem.representedObject] ||= menuItem.representedObject.alloc.init).showWindow(self)
  end
  
  def addWebViewTab(url = nil)
    @webViewControllers ||= []
    if url.is_a? OSX::NSURL
      @webViewControllers << WebViewController.alloc.initWithURL(url)
    else
      @webViewControllers << WebViewController.alloc.init
    end
    @tabView.addTabViewItem @webViewControllers.last.tabViewItem
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
  
  def registerDefaults
    # Make sure that SRAutoFillManager stores/retrieves usernames & passwords.
    OSX::NSUserDefaults.standardUserDefaults.registerDefaults({
      'autoFillUserPass' => true
    })
  end
  
  def loadBundles
    @bundle_window_controllers = {}
    
    [File.join(Rucola::RCApp.root_path, 'bundles'), Rucola::RCApp.application_support_path].each do |bundles|
      # Load all event handlers
      Dir.glob("#{bundles}/*.wabundle/event_handlers/*.rb").each do |event_handler|
        log.debug "Loading event handler: #{event_handler}"
        require event_handler
      end
      
      # Load all window controllers
      Dir.glob("#{bundles}/*.wabundle/controllers/*.rb").each do |controller|
        log.debug "Loading controller: #{controller}"
        require controller
        klass = File.to_const(controller)
        
        item = OSX::NSMenuItem.alloc.initWithTitle_action_keyEquivalent("#{klass.name.scan(/([A-Z][a-z]+)/).flatten[0..-2].join(' ')}...", 'openBundleWindowController:', '')
        item.target = self
        item.representedObject = klass
        
        @bundlesMenu.addItem(item)
      end
    end
  end
  
  def writeUserStyleSheet
    if stylesheet_path = WebApp::EventHandler.write_tmp_stylesheet!
      # And assign it to the WebView preferences.
      prefs = OSX::WebPreferences.standardPreferences
      prefs.userStyleSheetEnabled = true
      prefs.userStyleSheetLocation = OSX::NSURL.fileURLWithPath(stylesheet_path)
    end
  end
  
  def setupTabView
    @tabView.removeTabViewItem(@tabView.tabViewItemAtIndex(0))
    @tabView.delegate = @tabBarController
  end
  
  def setupTabBarController
    setupTabView
    
    @tabBarController.tabView = @tabView
    @tabBarController.setStyleNamed('Unified')
    @tabBarController.delegate = self
    @tabBarController.showAddTabButton = true
    button = @tabBarController.addTabButton
    button.target = self
    button.action = :addWebViewTab
  end
end