class WebViewController < OSX::NSObject
  kvc_accessor :isProcessing, :icon, :iconName, :objectCount
  attr_reader :webView, :tabViewItem, :objectController
  
  def init
    if super_init
      @url = OSX::NSURL.URLWithString(OSX::NSBundle.mainBundle.infoDictionary['WebAppURL']) if @url.nil?
      
      @webView = WebViewWithDragAndDrop.alloc.initWithDragDelegate(self)
      
      setup_tab_bar_item_values!
      create_tab_view_item!
      setup_event_handlers!
      
      @webView.frameLoadDelegate = self
      @webView.policyDelegate = self
      @webView.setUIDelegate(self)
      @webView.mainFrame.loadRequest OSX::NSURLRequest.requestWithURL(@url)
      
      self
    end
  end
  
  def initWithURL(url)
    @url = url
    init
  end
  
  def webView_didFinishLoadForFrame(webView, frame)
    log.debug "Page loaded: #{webView.mainFrameURL}"
    OSX::SRAutoFillManager.sharedInstance.fillFormsWithWebView(webView)
    @event_handlers.each { |e| e.register_dom_observers! }
    @tabViewItem.label = @webView.mainFrameTitle if @tabViewItem.label == 'Loading...'
    self.isProcessing = false
  end
  
  def webView_decidePolicyForNavigationAction_request_frame_decisionListener(webView, info, request, frame, listener)
    log.debug "Request done for: #{request.URL.absoluteString}"
    self.isProcessing = true
    
    navigationType = info[OSX::WebActionNavigationTypeKey].intValue
    OSX::SRAutoFillManager.sharedInstance.registerFormsWithWebView(webView) if navigationType == OSX::WebNavigationTypeFormSubmitted
    listener.use
  end
  
  def webView_decidePolicyForNewWindowAction_request_newFrameName_decisionListener(webView, info, request, newFrameName, listener)
    listener.ignore
    case newFrameName
    when '_open_in_new_tab' # FIXME: This creates a new window, but for some reason also instantiates a new tab..
      OSX::NSApp.delegate.addWebViewTab(request.URL)
    when '_close_tab'
      OSX::NSApp.delegate.removeWebViewTab(tabViewItem)
    else
      OSX::NSWorkspace.sharedWorkspace.openURL(request.URL)
    end
  end
  
  def webView_runOpenPanelForFileButtonWithResultListener(webView, listener)
    panel = OSX::NSOpenPanel.openPanel
    panel.allowsMultipleSelection = false
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    result = panel.runModalForTypes(nil)
    
    if result == OSX::NSOKButton
      listener.chooseFilename(panel.filenames.first)
    else
      listener.cancel
    end
  end
  
  # def webView_dragDestinationActionMaskForDraggingInfo(webView, draggingInfo)
  #   OSX::WebDragDestinationActionNone
  # end
  
  def webView_didReceiveDroppedFiles(webView, files)
    @event_handlers.each { |event_handler| event_handler.handle_files_dropped_event(files) }
  end
  
  private
  
  def setup_tab_bar_item_values!
    @isProcessing = false
    @icon = @iconName = nil
    @objectCount = 0
    @objectController = OSX::NSObjectController.alloc.initWithContent(self)
  end
  
  def create_tab_view_item!
    @tabViewItem = OSX::WebViewTabItem.alloc.initWithWebViewController(self)
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
    
    require Rucola::RCApp.root_path + "/lib/event_handlers/campfire.rb" unless defined? Campfire::Room
    [Campfire::Lobby, Campfire::Room].each do |event_handler_class|
      event_handler = event_handler_class.alloc.init
      event_handler.webViewController = self
      event_handler.webView = @webView
      @event_handlers << event_handler
    end
  end
  
end