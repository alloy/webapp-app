$WEBAPP_DEBUG = true

class ApplicationController < Rucola::RCController
  ib_outlet :main_window
  ib_outlet :webview
  
  def awakeFromNib
    # Make sure that SRAutoFillManager stores/retrieves usernames & passwords.
    OSX::NSUserDefaults.standardUserDefaults.registerDefaults({
      'autoFillUserPass' => true
    })
    #p OSX::NSUserDefaults.standardUserDefaults.boolForKey('autoFillUserPass')
    
    WebApp::Plugins.start
    
    url = OSX::NSBundle.mainBundle.infoDictionary['WebAppURL']
    
    @event_handlers = []
    event_handler_files = Dir.glob "#{RUBYCOCOA_ROOT + 'app/event_handlers/'}/*.rb"
    
    event_handler_files.each do |event_handler_file|
      require event_handler_file
      event_handler = File.constantize(event_handler_file).alloc.init
      event_handler.webView = @webview
      @event_handlers << event_handler
    end
    
    @webview.frameLoadDelegate = self
    @webview.policyDelegate = self
    @webview.mainFrame.loadRequest OSX::NSURLRequest.requestWithURL(OSX::NSURL.URLWithString(url))
  end
  
  def webView_didFinishLoadForFrame(webView, frame)
    OSX::SRAutoFillManager.sharedInstance.fillFormsWithWebView(webView)
    puts "Page done loading." if $WEBAPP_DEBUG
    @event_handlers.each { |e| e.register_dom_observers! }
  end
  
  def webView_decidePolicyForNavigationAction_request_frame_decisionListener(webView, info, request, frame, listener)
    navigationType = info[OSX::WebActionNavigationTypeKey].intValue
    OSX::SRAutoFillManager.sharedInstance.registerFormsWithWebView(webView) if navigationType == OSX::WebNavigationTypeFormSubmitted
    puts "Request done for: #{request.URL.absoluteString}" if $WEBAPP_DEBUG
    listener.use
  end
end