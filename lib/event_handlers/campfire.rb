# class Campfire < WebApp::EventHandler
#   plugin :growl, :channel_message => 'Received a new channel message.'
#   plugin :badge
#   
#   ROOM = /\/room\/\d+$/
#   
#   on_page_loaded do |url, title|
#     if url =~ ROOM
#       @room_name = title.sub(/^Campfire: /, '')
#       puts "Parsed channel name: #{@room_name}" if $WEBAPP_DEBUG
#     end
#   end
#   
#   on_event('DOMNodeInserted', :url => ROOM, :conditions => { :id => 'chat' }) do |event, node|
#     tr = (node/'tr').last
#     unless tr['class'] =~ /timestamp_message/
#       name, message = (tr/'td').map { |element| element.inner_text }
#       
#       unless same_as_last_time?(message)
#         puts "#{name}: #{message}"
#         growl_channel_message(@room_name, "#{name}: #{message}")
#         increase_badge_counter!
#       end
#     end
#   end
#   
# end

module Campfire
  class Room < WebApp::EventHandler(/\/room\/\d+$/)
    plugin :growl, :channel_message => 'Received a new channel message.'
    plugin :badge
    
    on_page_loaded do |url, title|
      @room_name = title.sub(/^Campfire: /, '')
      log.debug "Parsed channel name: #{@room_name}"
    end
    
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
    
    def base_url
      @base_url ||= document.URL.to_s.scan(/(https*:\/\/.*?)\//)[0][0]
    end
    
    def matches_criteria?(row)
      row.is_a?(OSX::DOMHTMLTableRowElement) and (Rucola::RCApp.debug? or not row.class?('you')) and not row.class?('timestamp_message')
    end
  end
end