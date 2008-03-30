class WebViewWithDragAndDrop < OSX::WebView
  attr_accessor :dragDelegate
  
  def _init
    if init
      unregisterDraggedTypes
      registerForDraggedTypes [OSX::NSFilenamesPboardType]
    
      self
    end
  end

  def initWithDragDelegate(dragDelegate)
    @dragDelegate = dragDelegate
    _init
  end

  def draggingEntered(sender)
    pboard = sender.draggingPasteboard
  
    if pboard.types.include? OSX::NSFilenamesPboardType
      return OSX::NSDragOperationLink
    else
      return OSX::NSDragOperationNone
    end
  end

  def performDragOperation(sender)
    pboard = sender.draggingPasteboard
  
    if pboard.types.include? OSX::NSFilenamesPboardType
      files = pboard.propertyListForType(OSX::NSFilenamesPboardType)
      dragDelegate.webView_didReceiveDroppedFiles(self, files) if dragDelegate.respond_to? :webView_didReceiveDroppedFiles
      true
    else
      false
    end
  end
end