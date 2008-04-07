module Campfire
  class All < WebApp::EventHandler
    # Hide the room tabs at the top of the page
    css %{
      #MainTabs li:first-child a
      {
        display: none;
      }
      
      #MainTabs a.chat
      {
        display: none;
      }
    }
  end
end