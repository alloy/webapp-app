class Twitter < WebApp::EventHandler
  plugin :growl, :tweet => 'Received a new tweet.'
  plugin :badge
  
  on_event('DOMNodeInserted') do |event, node|
    if contents = (node/'tr.hentry'/'td.content')
      message = content_for(contents, 'span.entry-content')
      unless message.nil? or same_as_last_time?(message)
        name = content_for(contents, 'strong/a')
        growl_tweet(name, message)
        increase_badge_counter!
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