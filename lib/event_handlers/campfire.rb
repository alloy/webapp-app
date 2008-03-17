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
#     last_row = (node/'tr').last
#     unless last_row['class'] =~ /timestamp_message/
#       name, message = (last_row/'td').map { |element| element.inner_text }
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
      last_row = node.lastChild
      if Rucola::RCApp.debug? or !message_from_self?(last_row)
        p last_row.firstChild.objc_methods.sort.grep(/text/i)
        name, message = last_row.firstChild.textContent.split(' ').first, last_row.lastChild.textContent
        
        log.debug "Channel message from #{name}: #{message}"
        growl_channel_message(@room_name, "#{name}: #{message}")
        increase_badge_counter!
      end
    end
    
    private
    
    def message_from_self?(row)
      row['class'].split(' ').include? 'you'
    end
  end
end