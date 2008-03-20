module Campfire
  class Room < WebApp::EventHandler(/\/room\/\d+$/)
    plugin :growl, :channel_message => 'Received a new channel message.'
    plugin :badge
    
    # Get the room name.
    on_page_loaded do |url, title|
      @room_name = title.sub(/^Campfire: /, '')
      log.debug "Parsed channel name: #{@room_name}"
    end
    
    # Get the username.
    on_page_loaded do |url, title|
      if @username.nil?
        user_id = document.find('#chat tr').last['class'].to_s.scan(/user_\d+/).first
        @username = document.find(:first, "##{user_id} span").textContent.to_s
      end
    end
    
    # - Also truncate the paste message even more if it has been tuncated so the growls don't get too big.
    # - Check if a message was directed at 'me' and make the growl sticky.
    # - If a message only contains a link, make clicking the growl open the link in a browser.
    on_event('DOMNodeInserted', :conditions => { :id => 'chat' }) do |event, node|
      tr = node.lastChild
      
      if matches_criteria?(tr)
        name, message = tr.find('td').map { |td| td.textContent }
        name = name.split(' ').first
        
        increase_badge_counter!
        
        if tr.class? 'paste_message'
          body = tr.find(:first, 'td.body div')
          
          if body.find(:first, 'span.number_of_lines')
            url = OSX::NSURL.URLWithString("#{base_url}#{ body.find(:first, 'a')['href'] }")
            log.debug "Truncated paste. from #{name}. URL: #{url.absoluteString}"
            growl_channel_message(@room_name, "#{name}: Truncated paste.") do
              OSX::NSWorkspace.sharedWorkspace.openURL(url)
            end
            
          else
            paste = body.find(:first, 'pre code').innerHTML
            log.debug "Normal paste from #{name}: #{paste}"
            growl_channel_message(@room_name, "#{name} pasted: #{paste}")
            
          end
        else
          log.debug "Channel message from #{name}: #{message}"
          growl_channel_message(@room_name, "#{name}: #{message}")
        end
      end
    end
    
    private
    
    def base_url
      @base_url ||= document.URL.to_s.scan(/(https*:\/\/.*?)\//)[0][0]
    end
    
    def matches_criteria?(row)
      row.is_a?(OSX::DOMHTMLTableRowElement) and (Rucola::RCApp.debug? or not row.class?('you')) and not row.class?('timestamp_message')
    end
  end
end