require File.expand_path('../campfire', __FILE__)

$WEBAPP_DEBUG = true

class ApplicationController < Rucola::RCController
  ib_outlet :main_window
  ib_outlet :webview
  
  def awakeFromNib
    WebApp::Plugins.start
    
    @event_handler = Campfire.alloc.init
    @event_handler.delegate = self
    @event_handler.webView = @webview
    
    url = 'http://fingertips.campfirenow.com'
    @webview.frameLoadDelegate = self
    @webview.mainFrame.loadRequest OSX::NSURLRequest.requestWithURL(OSX::NSURL.URLWithString(url))
  end
  
  def webView_didFinishLoadForFrame(webView, frame)
    @event_handler.register_dom_observers!
  end
end