class Twitter < WebApp::EventHandler
  plugin :growl, :tweet => 'Received a new tweet.'
  plugin :badge
  
  on_page_loaded do |url, title|
    if @username.nil?
      # Get the username from the /home page once.
      if url =~ /\/home$/
        links = (page_body/"div#container"/"div#side"/"div.section"/"div.user_icon"/"p")
        unless links.length.zero?
          @username = links.first.inner_text.strip
          puts "Parsed username is: #{@username}" if $WEBAPP_DEBUG
        end
      end
    end
  end
  
  on_event('DOMNodeInserted', :url => /\/home$/) do |event, node|
    if contents = (node/'tr.hentry'/'td.content')
      message = content_for(contents, 'span.entry-content')
      
      unless message.nil? or same_as_last_time?(message)
        name = content_for(contents, 'strong/a')
        
        if name != @username or $WEBAPP_DEBUG
          puts "Message send by yourself. Normally this wouldn't growl and increase the badge counter." if $WEBAPP_DEBUG
          
          if message =~ /^@#{@username}[:\s]+(.+)$/m
            puts "Sticky growl tweet: #{name}: #{$1}"
            sticky_growl_tweet(name, $1)
          else
            growl_tweet(name, message)
          end
          
          increase_badge_counter!
        end
      end
    end
  end
  
  private
  
  def content_for(contents, path)
    if rows = (contents/path)
      rows.first.inner_text.strip unless rows.length.zero?
    end
  end
end