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
    
    # url = 'http://fingertips.campfirenow.com'
    # @event_handler = Campfire.alloc.init
    
    url = 'https://twitter.com//home'
    @event_handler = Twitter.alloc.init
    
    @event_handler.delegate = self
    @event_handler.webView = @webview
    
    @webview.frameLoadDelegate = self
    @webview.policyDelegate = self
    @webview.mainFrame.loadRequest OSX::NSURLRequest.requestWithURL(OSX::NSURL.URLWithString(url))
  end
  
  def webView_didFinishLoadForFrame(webView, frame)
    OSX::SRAutoFillManager.sharedInstance.fillFormsWithWebView(webView)
    @event_handler.register_dom_observers!
  end
  
  def webView_decidePolicyForNavigationAction_request_frame_decisionListener(webView, info, request, frame, listener)
    navigationType = info[OSX::WebActionNavigationTypeKey].intValue
    OSX::SRAutoFillManager.sharedInstance.registerFormsWithWebView(webView) if navigationType == OSX::WebNavigationTypeFormSubmitted
    p request.URL.absoluteString
    listener.use
  end
end