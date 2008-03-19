module Campfire
  class Room < WebApp::EventHandler(/\/room\/\d+$/)
    plugin :growl, :channel_message => 'Received a new channel message.'
    plugin :badge
    
    on_page_loaded do |url, title|
      @room_name = title.sub(/^Campfire: /, '')
      log.debug "Parsed channel name: #{@room_name}"
    end
    
    # - Pastes need a special growl which take you to the pasted url immediatley if it has been truncated.
    #   Also truncate the paste message even more if it has been tuncated so the growls don't get too big.
    # - Check if a message was directed at 'me' and make the growl sticky.
    # - If a message only contains a link, make clicking the growl open the link in a browser.
    on_event('DOMNodeInserted', :conditions => { :id => 'chat' }) do |event, node|
      tr = node.lastChild
      
      if matches_criteria?(tr)
        name, message = (tr / 'td').map { |td| td.textContent }
        name = name.split(' ').first
        
        increase_badge_counter!
        
        if tr.class? 'paste_message'
          log.debug "Paste message from #{name}"
          body = (tr / 'td[@class="body"]/div').first
          
          if (body / 'span[@class="number_of_lines"]').empty?
            paste = (body / 'pre/code').first.innerHTML
            log.debug "Normal paste from #{name}: #{paste}"
            growl_channel_message(@room_name, "#{name}: #{paste}")
            
          else
            url = OSX::NSURL.URLWithString("#{base_url}#{ (body / 'a').first['href'] }")
            log.debug "Truncated paste. URL: #{url.absoluteString}"
            growl_channel_message(@room_name, "#{name}: Truncated paste.") do
              OSX::NSWorkspace.sharedWorkspace.openURL(url)
            end
            
          end
        else
          log.debug "Channel message from #{name}: #{message}"
          growl_channel_message(@room_name, "#{name}: #{message}")
        end
      end
    end
    
    private
    
    
    # find('div.bla') # => [Elm]
    # find(:css => 'div.bla') # => [Elm]
    # find(:all, :css => 'div.bla') # => [Elm]
    # find(:xpath => 'div/span') # => [Elm]
    # find(:all, :xpath => 'div/span') # => [Elm]
    # 
    # find(:first, 'div.bla') # => Elm
    # find(:first, :css => 'div.bla') # => Elm
    # find(:first, :xpath => 'div/span') # => Elm
    # 
    # def find(*args)
    #   limit = :all
    #   options = {}
    #   
    #   if args.length == 1 and args[0].is_a?(String)
    #     options[:css] = args.first
    #   elsif args.length == 2 and args[0].is_a?(Symbol)
    #     limit = args[0]
    #     if args[1].is_a? String
    #       options[:css] = args[1]
    #     elsif args[1].is_a? Hash
    #       options.merge!(args[1])
    #     else
    #       raise ArgumentError
    #     end
    #   else
    #     raise ArgumentError
    #   end
    #   
    #   if options[:css]
    #     if limit == :all
    #       querySelectorAll(options[:css]).to_a
    #     elsif limit == :first
    #       querySelector(options[:css])
    #     end
    #   elsif options[:xpath]
    #     if limit == :all
    #       evaluate_contextNode_resolver_type_inResult(options[:xpath], self, nil, OSX::DOM_ANY_TYPE, nil).to_a
    #     elsif limit == :first
    #       evaluate_contextNode_resolver_type_inResult(options[:xpath], self, nil, OSX::DOM_ANY_TYPE, nil).to_a.first
    #     end
    #   end
    # end
    
    def base_url
      @base_url ||= document.URL.to_s.scan(/(https*:\/\/.*?)\//)[0][0]
    end
    
    def matches_criteria?(row)
      row.is_a?(OSX::DOMHTMLTableRowElement) and (Rucola::RCApp.debug? or not row.class?('you')) and not row.class?('timestamp_message')
    end
  end
end