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
    
    setup_tabView!
    setup_tabBarController!
    
    @webViewControllers = []
    addWebViewTab
  end
  
  def addWebViewTab(sender = nil)
    @webViewControllers << WebViewController.alloc.init
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