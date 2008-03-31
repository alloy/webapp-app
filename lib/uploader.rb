class Uploader < OSX::NSObject
  BOUNDARY = '0xKhTmLbOuNdArY'
  
  attr_accessor :url, :name, :file, :delegate
  
  def initWithURL_name_file_delegate(url, name, file, delegate)
    if init
      @url, @name, @file, @delegate = url, name, file, delegate
      self
    end
  end
  
  def upload!
    log.debug "Will try to upload '#{@file}' to url '#{@url}' for input key '#{@name}'"
    
    file_data = OSX::NSData.dataWithContentsOfFile(@file)
    request = OSX::NSMutableURLRequest.requestWithURL(OSX::NSURL.URLWithString(@url))
    request.setHTTPMethod('POST')
    request.setValue_forHTTPHeaderField("multipart/form-data boundary=#{BOUNDARY}", 'Content-Type')
    
    post_data = OSX::NSMutableData.dataWithCapacity(file_data.length + 512)
    
    [ "--#{BOUNDARY}\r\n",
      "Content-Disposition: form-data; name=\"#{@name}\"; filename=\"#{File.basename(@file)}\"\r\n\r\n",
      file_data,
      "\r\n--#{BOUNDARY}--\r\n"
    ].each do |obj|
      post_data.appendData(obj.is_a?(OSX::NSData) ? obj : OSX::NSString.stringWithFormat(obj).dataUsingEncoding(OSX::NSUTF8StringEncoding))
    end
    request.setHTTPBody(post_data)
    
    OSX::NSURLConnection.alloc.initWithRequest_delegate(request, self)
  end
  
  def connectionDidFinishLoading(connection)
    @delegate.connectionDidFinishLoading(connection)
  end
  
  def connection_didFailWithError(connection, error)
    @delegate.connection_didFailWithError(connection, error)
  end
end