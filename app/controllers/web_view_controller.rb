class WebViewController < Rucola::RCController
  kvc_accessor :isProcessing, :icon, :iconName, :objectCount
  attr_reader :tabViewItem
  
  def after_init
    @webView = OSX::WebView.alloc.init
    setup_tab_bar_item_values!
    create_tab_view_item!
  end
  
  private
  
  def setup_tab_bar_item_values!
    @isProcessing = false
    @icon = @iconName = nil
    @objectCount = 0
    @objectController = OSX::NSObjectController.alloc.initWithContent(self)
  end
  
  def create_tab_view_item!
    @tabViewItem = OSX::NSTabViewItem.alloc.initWithIdentifier(@objectController)
    @tabViewItem.label = "Bla: #{object_id}"
    @tabViewItem.view = @webView
  end
end