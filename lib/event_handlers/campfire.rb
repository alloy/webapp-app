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
      if @first_name.nil?
        if row = document.find('#chat tr').last
          user_id = row['class'].to_s.scan(/user_\d+/).first
          @first_name, @last_name = document.find(:first, "##{user_id} span").textContent.to_s.split(' ')
          log.debug "Parsed username: #{@first_name} #{@last_name}"
        end
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
          if message_directed_at_me?(message)
            log.debug "Channel message directed at you from #{name}: #{message}"
            sticky_growl_channel_message(@room_name, "#{name}: #{message}")
          else
            log.debug "Channel message from #{name}: #{message}"
            growl_channel_message(@room_name, "#{name}: #{message}")
          end
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
    
    def message_directed_at_me?(message)
      !!(message.to_s =~ /^#{@first_name}/i)
    end
  end
end