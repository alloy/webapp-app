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
        #name, message = tr.children.item(0).textContent.split(' ').first, tr.children.item(1).textContent
        name, message = (tr / 'td').map { |td| td.textContent }
        name = name.split(' ').first
        
        log.debug "Channel message from #{name}: #{message}"
        increase_badge_counter!
        
        # growl_channel_message(@room_name, "#{name}: #{message}")
        
        # p tr
        # p tr['class']
        
        # if tr.class? 'paste_message'
        #   log.debug "Paste message from #{name}"
        #   
        #   body = tr.to_a.last
        #   code = body.to_a[0].to_a
        #   
        #   if code[1].class?('number_of_lines')
        #     log.debug "Truncated paste. URL: ..."
        #     growl_channel_message(@room_name, "#{name}: Truncated paste:\n#{message}", lambda {
        #       puts 'callback!'
        #       OSX::NSWorkspace.sharedWorkspace.openURL(OSX::NSURL.URLWithString('http://www.google.com'))
        #     })
        #   end
        # else
        #   #growl_channel_message(@room_name, "#{name}: #{message}")
        #   growl_channel_message(@room_name, "#{name}: Truncated paste:\n#{message}") do
        #     OSX::NSWorkspace.sharedWorkspace.openURL(OSX::NSURL.URLWithString('http://www.google.com'))
        #   end
        # end
        
        if tr.class? 'paste_message'
          log.debug "Paste message from #{name}"
          body = (tr / 'td[@class="body"]/div').first
          
          if (body / 'span[@class="number_of_lines"]').empty?
            log.debug "Normal paste"
          else
            url = OSX::NSURL.URLWithString("#{base_url}#{ (body / 'a').first['href'] }")
            log.debug "Truncated paste. URL: #{url.absoluteString}"
            
            growl_channel_message(@room_name, "#{name}: Truncated paste.") do
              OSX::NSWorkspace.sharedWorkspace.openURL(url)
            end
          end
        else
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