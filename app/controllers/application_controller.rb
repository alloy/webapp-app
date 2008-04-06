$WEBAPP_DEBUG = true

class ApplicationController < Rucola::RCController
  ib_outlet :main_window
  ib_outlet :tabView
  ib_outlet :tabBarController
  
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
    
    # If there are any custom user css rules, now is the time to write them out.
    if stylesheet_path = WebApp::EventHandler.write_tmp_stylesheet!
      # And assign it to the WebView preferences.
      prefs = OSX::WebPreferences.standardPreferences
      prefs.userStyleSheetEnabled = true
      prefs.userStyleSheetLocation = OSX::NSURL.fileURLWithPath(stylesheet_path)
    end
    
    ["#{Rucola::RCApp.root_path}/bundles/", Rucola::RCApp.application_support_path].each do |bundles|
      # Load all event handlers
      Dir.glob("#{bundles}/*.wabundle/event_handlers/*.rb").each do |event_handler|
        require event_handler
      end
      
      # Load all controllers
      Dir.glob("#{bundles}/*.wabundle/controllers/*.rb").each do |controller|
        require controller
        #p File.constantize(controller)
      end
    end
    
    @webViewControllers = []
    addWebViewTab
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
  
  def openPreferences
    @campfire_preferences_controller ||= CampfirePreferencesController.alloc.init
    @campfire_preferences_controller.showWindow(self)
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