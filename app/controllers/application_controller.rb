$WEBAPP_DEBUG = true

class ApplicationController < Rucola::RCController
  ib_outlet :main_window
  ib_outlet :tabView
  ib_outlet :tabBarController
  
  def awakeFromNib
    # Make sure that SRAutoFillManager stores/retrieves usernames & passwords.
    OSX::NSUserDefaults.standardUserDefaults.registerDefaults({
      'autoFillUserPass' => true
    })
    
    WebApp::Plugins.start
    
    setup_tabView!
    setup_tabBarController!
    
    @webViewControllers = []
    addWebViewTab
  end
  
  def addWebViewTab(sender = nil)
    @webViewControllers << WebViewController.alloc.init
    @tabView.addTabViewItem @webViewControllers.last.tabViewItem
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