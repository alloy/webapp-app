module WebApp
  class << self
    def EventHandler(url)
      @klass_counter ||= 0
      klass = eval %{
        class WebApp::NamelessEventHandler_#{@klass_counter} < EventHandler
          class << self
            def inherited(subklass)
              super
              subklass.global_url = global_url
            end
          end
          
          self
        end
      }
      klass.global_url = url
      klass
    end
  end
  
  class EventHandler < OSX::NSObject
    class << self
      attr_accessor :global_url
      
      attr_writer :event_handlers
      def event_handlers
        @event_handlers ||= []
      end
      
      def inherited(subklass)
        super
        event_handlers << subklass unless subklass.name =~ /NamelessEventHandler_/
      end
    end
    
    attr_accessor :delegate
    attr_accessor :webView
    attr_accessor :webViewController
    attr_reader :badge_counter
    
    def initialize
      @badge_counter = 0
      @registered_events_for_this_page = []
    end
    
    class << self
      # Called whenever a page is done loading. It takes 2 arguments, which are the page +url+ and the page +title+.
      #
      # Example from the Campfire plugin:
      #
      #   class Campfire < WebApp::EventHandler
      #     on_page_loaded do |url, title|
      #       @room_name = title.sub(/Campfire: /, '')
      #     end
      #   end
      def on_page_loaded(url = nil, &block)
        on_event('WebAppPageDidLoad', :url => url, &block)
      end
      
      # Register a callback for a DOMEvent. It takes 2 arguments, which are the even +name+ and an optional +options+ hash.
      #
      # Example from the Campfire plugin:
      #
      #   class Campfire < WebApp::EventHandler
      #     on_event('DOMNodeInserted', :conditions => { :id => 'chat' }) do |event, node|
      #       last_row = (node/'tr').last
      #       unless last_row['class'] =~ /timestamp_message/
      #         name, message = (last_row/'td').map { |element| element.inner_text }
      #         growl(@room_name, "#{name}: #{message}")
      #         increase_badge_counter!
      #       end
      #     end
      #   end
      def on_event(name, options = {}, &block)
        options[:conditions] ||= {}
        
        @event_handlers ||= []
        
        event_handler_method = "event_handler_method_#{@event_handlers.length + 1}".to_sym
        @event_handlers.push({ :name => name, :options => options, :event_handler_method => event_handler_method})
        
        # define the event handler method as a private instance method
        define_method(event_handler_method, &block)
        private event_handler_method
      end
    end
    
    def register_dom_observers! # :nodoc:
      @registered_events_for_this_page = [] # flush the registered events
      @document = @webView.mainFrame.DOMDocument
      
      if event_handlers = self.class.instance_variable_get(:@event_handlers)
        event_handlers.each do |event_handler|
          url = @document.URL.to_s
          log.debug "Page loaded: #{url}"
          
          if for_this_url?(url, event_handler)
            if event_handler[:name] == 'WebAppPageDidLoad'
              log.debug "Calling page loaded event handler: #{event_handler[:event_handler_method]}"
              send(event_handler[:event_handler_method], url, @document.title.to_s)
            else
              log.debug "Register for event: #{event_handler[:name]}, with optional url regex: #{event_handler[:options][:url]}"
              register_event_for_this_page(@document, event_handler)
            end
          end
        end
      end
    end
    
    def document
      @document
    end
    
    def handleEvent(event) # :nodoc:
      #puts "Handle event: #{event}" if $WEBAPP_DEBUG
      node = event.relatedNode
      
      @registered_events_for_this_page.each do |event_handler|
        # skip if it's not an event we handle or if it's the same node as last time.
        # TODO: check if we need an option to allow multiple times the same node...
        
        # FIXME: Nu tijdelijk terug naar de oude situatie...
        next unless event_matches_handler?(event, event_handler)
        
        # next unless event_matches_handler?(event, event_handler) and @last_node != node
        # @last_node = node.copy
        
        # next unless event_matches_handler?(event, event_handler) and @last_node != node.outerHTML
        # @last_node = node.copy.outerHTML
        # puts "Last node was:", ''
        # p @last_node
        # puts 'Current node is:', ''
        # p node.outerHTML
        # # FIXME: Het probleem is dat er soms wel of niet whitespace bij is gekomen....
        
        #send(event_handler[:event_handler_method], event, Hpricot(node.outerHTML.to_s)) # hpricot
        log.debug "Calling event handler: #{event_handler[:event_handler_method]}"
        send(event_handler[:event_handler_method], event, node)
      end
    end
    
    # Helper methods

    # Checks if this +content+ is the same as the last time.
    # It also stores the content so it can be checked the next time.
    def same_as_last_time?(content)
      @last_content ||= ''
      result = (@last_content == content)
      @last_content = content if result == false
      result
    end
    
    private
    
    def for_this_url?(url, event_handler)
      (event_handler[:options][:url].nil? and self.class.global_url.nil?) or (url =~ event_handler[:options][:url]) or (event_handler[:options][:url].nil? and url =~ self.class.global_url)
    end
    
    def event_matches_handler?(event, handler)
      attributes = event.relatedNode.attributes
      event.objc_send(:type) == handler[:name] and handler[:options][:conditions].all? do |key, value|
        item = attributes.getNamedItem(key.to_s)
        not item.nil? and item.value == value
      end
    end
    
    def register_event_for_this_page(doc, event_handler)
      @registered_events_for_this_page << event_handler
      doc.addEventListener___(event_handler[:name], self, true)
    end
  end
end