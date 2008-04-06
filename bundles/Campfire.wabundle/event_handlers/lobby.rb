module Campfire
  class Lobby < WebApp::EventHandler(/https*:\/\/.+?\/$/)
    # Make the room links open in a new tab
    on_page_loaded do |url, title|
      open_room_links_in_new_tab(document)
    end
    
    # Every now and then the room links get refreshed so we need to update them again
    on_event('DOMNodeInserted', :conditions => { :id => 'lobby' }) do |event, node|
      open_room_links_in_new_tab(node)
    end
    
    private
    
    def open_room_links_in_new_tab(node)
      node.find('div.room a').each { |link| link.open_in_new_tab! }
    end
  end
end