require 'fileutils'

module WebApp
  class << self
    def EventHandler(url)
      @klass_counter ||= 0
      @klass_counter += 1
      
      klass = eval "class WebApp::NamelessEventHandler_#{@klass_counter} < EventHandler; self; end"
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
        subklass.global_url = global_url
        EventHandler.event_handlers << subklass unless subklass.name =~ /NamelessEventHandler_/
      end
      
      # Define custom CSS rules which will all be compiled into 1 stylesheet at startup.
      def css(rules)
        rules = rules.to_s.unindent
        if user_css_rules = WebApp::EventHandler.instance_variable_get(:@user_css_rules)
          rules = "#{user_css_rules}\n#{rules}"
        end
        WebApp::EventHandler.instance_variable_set(:@user_css_rules, rules)
      end
      
      def write_tmp_stylesheet!
        if user_css_rules = WebApp::EventHandler.instance_variable_get(:@user_css_rules)
          tmp_path = File.join('/tmp', 'WebApp', Rucola::RCApp.app_name)
          FileUtils.mkdir_p(tmp_path) unless File.exist?(tmp_path)
          
          stylesheet_path = File.join(tmp_path, 'user_stylesheet.css')
          File.open(stylesheet_path, 'w') do |file|
            file.write user_css_rules
          end
          
          stylesheet_path
        end
      end
    end
    
    attr_accessor :delegate
    attr_accessor :webView
    attr_accessor :webViewController
    attr_reader :badge_counter
    
    def initialize
      @badge_counter = 0
      @registered_events_for_this_page = []
      
      @bring_app_and_tab_to_the_front = Proc.new do
        OSX::NSApp.activateIgnoringOtherApps(true)
        log.debug "From bring app to the front proc: #{webViewController.inspect}"
        webViewController.tabViewItem.tabView.selectTabViewItem(webViewController.tabViewItem)
      end
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
        options = {}
        options[:url] = url unless url.nil?
        on_event('WebAppPageDidLoad', options, &block)
      end
      
      def on_files_dropped(url = nil, &block)
        options = {}
        options[:url] = url unless url.nil?
        on_event('WebAppFilesDropped', options, &block)
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
      
      def default_preferences(preferences)
        OSX::NSUserDefaults.standardUserDefaults.registerDefaults(preferences)
      end
    end
    
    def register_dom_observers! # :nodoc:
      @registered_events_for_this_page = [] # flush the registered events
      @document = @webView.mainFrame.DOMDocument
      
      if event_handlers = self.class.instance_variable_get(:@event_handlers)
        event_handlers.each do |event_handler|
          url = @document.URL.to_s
          
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
    
    def handleEvent(event) # :nodoc:
      @registered_events_for_this_page.each do |event_handler|
        if event.is_a? Hash
          next unless event[:name] == event_handler[:name]
          log.debug "Calling files dropped event handler: #{event_handler[:event_handler_method]}"
          send(event_handler[:event_handler_method], event[:files])
        else
          next unless event_matches_handler?(event, event_handler)
          log.debug "Calling event handler: #{event_handler[:event_handler_method]}"
          send(event_handler[:event_handler_method], event, event.relatedNode)
        end
      end
    end
    
    def handle_files_dropped_event(files)
      handleEvent :name => 'WebAppFilesDropped', :files => files
    end
    
    # Helpers
    
    def document
      @document
    end
    
    def element(id)
      @document.getElementById(id)
    end
    
    def upload(options)
      raise ArgumentError, "You need to specify a :file" unless options[:file]
      
      if options[:url] and options[:name]
      elsif options[:form]
        log.debug "Will try to parse the url and name from the form with selector: #{options[:form]}"
        form = document.find(:first, options[:form])
        url = form['action']
        name = form.find('input').select {  |input| input['type'] == 'file' }.first['name']
      else
        raise ArgumentError, "Should specify a CSS selector for :form or alternatively :url and :name"
      end
      
      uploader_instance = Uploader.alloc.initWithURL_name_file_delegate(url, name, options[:file], self)
      uploader_instance.upload!
    end
    
    def preferences
      OSX::NSUserDefaults.standardUserDefaults
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