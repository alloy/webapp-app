class Campfire < WebApp::EventHandler
  plugin :growl, :channel_message => 'Received a new channel message.'
  plugin :badge
  
  on_page_loaded do |url, title|
    @room_name = title.sub(/Campfire: /, '')
  end
  
  on_event('DOMNodeInserted', :conditions => { :id => 'chat' }) do |event, node|
    last_row = (node/'tr').last
    unless last_row['class'] =~ /timestamp_message/
      name, message = (last_row/'td').map { |element| element.inner_text }
      unless same_as_last_time?(message)
        growl_channel_message(@room_name, "#{name}: #{message}")
        increase_badge_counter!
      end
    end
  end
  
end