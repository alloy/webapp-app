# module WebApp
#   class Plugin
#     def webView_didFinishLoadForFrame(webview, frame)
#       register_dom_observers(webview.mainFrame)
#     end
#   
#     class << self
#       def on_event(name, options = {}, &block)
#         options[:multiple_times] ||= false
#       
#         (@events ||= []).push({ :name => name, :options => options, :block => block})
#       end
#     end
#   
#     private
#   
#     def register_dom_observers(frame)
#       doc = frame.DOMDocument
#       self.class.instance_variable_get(:@events).each { |event| doc.addEventListener___(event[:name], self, true) }
#     end
#   
#     def handleEvent(event)
#       self.class.instance_variable_get(:@events).each do |event_handler|
#         next unless event_matches_handler?(event, event_handler)
#         # FIXME: need to make sure we don't call multiple times for the same node
#         event_handler[:block].call(event, Hpricot(event.relatedNode.outerHTML.to_s)) # hpricot
#       end
#     end
#   
#     def event_matches_handler?(event, handler)
#       attributes = event.relatedNode.attributes
#       event.objc_send(:type) == handler[:name] and handler[:options][:conditions].all? { |key, value| attributes.getNamedItem(key.to_s).value == value }
#     end
#   
#     def growl(name, message)
#       puts "Growl: #{name}: #{message}"
#     end
#   
#     def increase_badge_counter!
#       # whatever
#     end
#   end
# end
# 
# class CampFire < WebApp::Plugin
#   
#   on_event('DOMNodeInserted', :conditions => { :id => 'chat' }) do |event, node|
#     last_row = (node/'tr').last
#     unless last_row.nil?
#       name, message = (last_row/'td').map { |element| element.inner_text }
#       growl(name, message)
#       increase_badge_counter!
#     end
#   end
#   
# end

class ApplicationController < Rucola::RCController
  ### IMPLEMENTATION
  
  ib_outlet :main_window
  ib_outlet :webview
  
  def awakeFromNib
    # All the application delegate methods will be called on this object.
    OSX::NSApp.delegate = self
    
    @growl = GrowlController.alloc.init
    p @growl
    
    @webview.frameLoadDelegate = self
    
    url = 'http://fingertips.campfirenow.com'
    @webview.mainFrame.loadRequest OSX::NSURLRequest.requestWithURL(OSX::NSURL.URLWithString(url))
  end
  
  def webView_didFinishLoadForFrame(webview, frame)
    __register_dom_observers(webview.mainFrame)
  end
  
  class << self
    def on_event(name, options = {}, &block)
      options[:multiple_times] ||= false
      
      (@events ||= []).push({ :name => name, :options => options, :block => block})
    end
  end
  
  def __register_dom_observers(frame)
    doc = frame.DOMDocument
    self.class.instance_variable_get(:@events).each { |event| doc.addEventListener___(event[:name], self, true) }
  end
  
  def handleEvent(event)
    self.class.instance_variable_get(:@events).each do |event_handler|
      next unless __event_matches_handler?(event, event_handler)
      # FIXME: need to make sure we don't call multiple times for the same node
      event_handler[:block].call(event, Hpricot(event.relatedNode.outerHTML.to_s)) # hpricot
    end
  end
  
  def __event_matches_handler?(event, handler)
    attributes = event.relatedNode.attributes
    event.objc_send(:type) == handler[:name] and handler[:options][:conditions].all? { |key, value| attributes.getNamedItem(key.to_s).value == value }
  end
  
  def growl(name, message)
    puts "Growl: #{name}: #{message}"
  end
  
  #### WHAT IT WOULD LOOK LIKE:
  
  on_event('DOMNodeInserted', :conditions => { :id => 'chat' }) do |event, node|
    last_row = (node/'tr').last
    unless last_row.nil?
      name, message = (last_row/'td').map { |element| element.inner_text }
      growl(name, message)
    end
  end
end