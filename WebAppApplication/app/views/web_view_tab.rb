class WebViewTabItem < OSX::NSTabViewItem
  attr_reader :webViewController
  
  def init
    if super_init
      self.label = 'Loading...'
      self
    end
  end
  
  def initWithWebViewController(webViewController)
    if init
      @webViewController = webViewController
      self.identifier = webViewController.objectController
      self.view = webViewController.webView
      self
    end
  end
end