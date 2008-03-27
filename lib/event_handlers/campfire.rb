module Campfire
  class Lobby < WebApp::EventHandler
    on_page_loaded(/https*:\/\/.+?\/$/) do |url, title|
      # Hide the room tabs
      document.find('#MainTabs a.chat').each { |link| link['style'] = 'display: none;' }
      # Make the room links open a new tab
      document.find('table.lobby div.room a').each { |link| link['target'] = '_open_in_new_tab' }
    end
  end
  
  class Room < WebApp::EventHandler(/\/room\/\d+$/)
    plugin :badge
    plugin :growl, :message => 'Message received',
                   :message_about_me => 'Message about/targeted at me',
                   :entered_or_left => 'Enter/leave message'
    
    on_page_loaded do |url, title|
      # Hide the room tabs
      document.find('#MainTabs a.chat').each { |link| link['style'] = 'display: none;' }
    end
    
    # Get the room name.
    on_page_loaded do |url, title|
      @room_name = title.sub(/^Campfire: /, '')
      log.debug "Parsed channel name: #{@room_name}"
      webViewController.tabViewItem.label = @room_name
    end
    
    # Get the username.
    on_page_loaded do |url, title|
      if @first_name.nil?
        if row = document.find('#chat tr').last
          user_id = row['class'].to_s.scan(/user_\d+/).first
          if username = document.find(:first, "##{user_id} span")
            @first_name, @last_name = username.textContent.to_s.split(' ')
            log.debug "Parsed username: #{@first_name} #{@last_name}"
          end
        end
      end
    end
    
    on_event('DOMNodeInserted', :conditions => { :id => 'chat' }) do |event, node|
      tr = node.lastChild
      
      if matches_criteria?(tr)
        name, message = tr.find('td').map { |td| td.textContent }
        name = name.split(' ').first
        
        if tr.class? 'enter_message'
          log.debug "Someone entered the room: #{name}"
          growl_entered_or_left(@room_name, "#{name} #{message}")
          # Don't increase the counter.
          
        elsif tr.class? 'kick_message'
          log.debug "Someone left the room: #{name}"
          growl_entered_or_left(@room_name, "#{name} #{message}")
          # Don't increase the counter.
          
        else
          increase_badge_counter!
          
          if tr.class? 'paste_message'
            body = tr.find(:first, 'td.body div')
            
            # Check if it was a truncated paste.
            if body.find(:first, 'span.number_of_lines')
              url = "#{base_url}#{ body.find(:first, 'a')['href'] }"
              log.debug "Truncated paste. from #{name}. URL: #{url}"
              growl_message_and_open_url("#{name}: Truncated paste.", url)
              
            else
              paste = body.find(:first, 'pre code').innerHTML
              log.debug "Normal paste from #{name}: #{paste}"
              growl_message(@room_name, "#{name} pasted: #{paste}")
              
            end
          else
            if message_about_or_at_me?(message)
              log.debug "Channel message directed at or about you from #{name}: #{message}"
              sticky_growl_message_about_me(@room_name, "#{name}: #{message}")
              
              # Check if the message only contains a link.
            elsif a = tr.find(:first, "td.body a")
              url = a['href']
              message = "#{name}: #{url}"
              log.debug "URL only message from #{message}"
              growl_message_and_open_url(message, url)
              
            else
              # Normal channel message.
              log.debug "Channel message from #{name}: #{message}"
              growl_message(@room_name, "#{name}: #{message}")
            end
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
    
    def message_about_or_at_me?(message)
      return false if @first_name.nil?
      message.downcase.include? @first_name.downcase
    end
    
    def growl_message_and_open_url(message, url)
      growl_message(@room_name, message) do
        OSX::NSWorkspace.sharedWorkspace.openURL(OSX::NSURL.URLWithString(url))
      end
    end
  end
end