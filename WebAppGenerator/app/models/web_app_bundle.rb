class WebAppBundle < OSX::NSObject
  class << self
    def bundles
      @bundles ||= Dir.glob("#{Rucola::RCApp.root_path}/bundles/*.wabundle").map do |path|
        WebAppBundle.alloc.initWithPath(path)
      end
    end
    
    def bundle_for_url(url)
      bundles.find { |bundle| bundle.url_match? url }
    end
  end
  
  attr_reader :path, :name
  
  def initWithPath(path)
    if init
      @path = path
      @name = path.scan(/(\w+)\.wabundle$/).first.first
      @url_regexp = Regexp.new(File.read(File.join(path, 'url_regexp')).strip)
      self
    end
  end
  
  def icon
    Dir.glob("#{@path}/icon.*").first
  end
  
  def url_match?(url)
    !!(url =~ @url_regexp)
  end
end