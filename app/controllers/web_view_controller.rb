class WebViewController < OSX::NSObject
  kvc_accessor :isProcessing, :icon, :iconName, :objectCount
  attr_reader :tabViewItem
  
  def init
    if super_init
      @url = OSX::NSBundle.mainBundle.infoDictionary['WebAppURL']
      
      @webView = OSX::WebView.alloc.init
      
      setup_tab_bar_item_values!
      create_tab_view_item!
      setup_event_handlers!
      
      @webView.frameLoadDelegate = self
      @webView.policyDelegate = self
      @webView.mainFrame.loadRequest OSX::NSURLRequest.requestWithURL(OSX::NSURL.URLWithString(@url))
      
      self
    end
  end
  
  def webView_didFinishLoadForFrame(webView, frame)
    OSX::SRAutoFillManager.sharedInstance.fillFormsWithWebView(webView)
    @event_handlers.each { |e| e.register_dom_observers! }
  end
  
  def webView_decidePolicyForNavigationAction_request_frame_decisionListener(webView, info, request, frame, listener)
    log.debug "Request done for: #{request.URL.absoluteString}"
    navigationType = info[OSX::WebActionNavigationTypeKey].intValue
    OSX::SRAutoFillManager.sharedInstance.registerFormsWithWebView(webView) if navigationType == OSX::WebNavigationTypeFormSubmitted
    listener.use
  end
  
  def webView_decidePolicyForNewWindowAction_request_newFrameName_decisionListener(webView, info, request, newFrameName, listener)
    listener.ignore
    OSX::NSWorkspace.sharedWorkspace.openURL(request.URL)
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
  
  def setup_event_handlers!
    @event_handlers = []
    # event_handler_files = Dir.glob "#{RUBYCOCOA_ROOT + 'lib/event_handlers/'}/campfire.rb"
    # 
    # event_handler_files.each do |event_handler_file|
    #   require event_handler_file
    #   #p WebApp::EventHandler::event_handlers
    #   
    #   #event_handler = File.constantize(event_handler_file).alloc.init
    #   event_handler = Campfire::Room.alloc.init
    #   p event_handler.methods(false)
    #   # event_handler.webView = @webView
    #   @event_handlers << event_handler
    # end
    
    require Rucola::RCApp.root_path + "/lib/event_handlers/campfire.rb"
    event_handler = Campfire::Room.alloc.init
    event_handler.webView = @webView
    @event_handlers << event_handler
  end
  
end