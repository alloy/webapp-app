require File.expand_path('../../test_helper', __FILE__)

#Rucola::Log.instance.level = 0

require "event_handlers/all"
require "event_handlers/lobby"
require "event_handlers/room"

# This is a stupid fix for the problem that the super_foo syntax is broken when OSX._ignore_ns_override is set to true.
class OSX::NSObject
  def super_init
    true
  end
end

unless defined? OSX::SRAutoFillManager
  class OSX::SRAutoFillManager
    def self.sharedInstance
      @instance ||= new
    end
    def fillFormsWithWebView(webView); end
  end
end

BASE_HOST = 'example.campfirenow.com'
BASE_URL = "https://#{BASE_HOST}"

describe "Campfire::Room, when setting up" do
  tests Campfire::Room
  
  it "should initialize" do
    handler.should.be.instance_of Campfire::Room
  end
  
  it "should only match room urls" do
    "http://#{BASE_HOST}/room/12345".should.match Campfire::Room.global_url
    "https://#{BASE_HOST}/room/12345".should.match Campfire::Room.global_url
    
    "#{BASE_URL}/bla".should.not.match Campfire::Room.global_url
  end
end

describe "Campfire::Room, when running" do
  tests Campfire::Room
  
  def after_setup
    url = "#{BASE_URL}/room/144516"
    
    assigns(:webViewController, WebViewController.alloc.initWithURL(OSX::NSURL.URLWithString(url)))
    load_page url, html_for_fixture('campfire_room')
    
    @chat = element('chat')
  end
  
  it "should parse the name of the room on page loaded" do
    assigns(:room_name).should == 'WebAppTestRoom'
  end
  
  it "should parse the name of the user by getting the last enter message after the first room page has been loaded" do
    [assigns(:first_name), assigns(:last_name)].should == %w{ Eloy Duran }
  end
  
  it "should detect that a new message has been posted in the channel" do
    row_node = build do
      tr.message_123456! :class => "text_message message user_123456" do
        td.person { span "Eloy D." }
        td.body { div "Hello world!" }
      end
    end
    
    handler.expects(:growl_message).with('WebAppTestRoom', "Eloy: Hello world!")
    handler.expects(:increase_badge_counter!)
    
    @chat.appendChild(row_node)
  end
  
  it "should only handle nodes which are table row nodes" do
    div_node = build { div "whatever" }
    
    handler.expects(:growl_message).times(0)
    handler.expects(:increase_badge_counter!).times(0)
    
    @chat.appendChild(div_node)
  end
  
  it "should not do anything if a message is from the user" do
    row_node = build do
      tr.message_123456! :class => "text_message message user_123456 you" do
        td.person { span "Eloy D." }
        td.body { div "Hello world!" }
      end
    end
    
    handler.expects(:growl_message).times(0)
    handler.expects(:increase_badge_counter!).times(0)
    
    @chat.appendChild(row_node)
  end
  
  it "should not do anything for timestamp messages" do
    row_node = build do
      tr.message_123456! :class => "timestamp_message message"
    end
    
    handler.expects(:growl_message).times(0)
    handler.expects(:increase_badge_counter!).times(0)
    
    @chat.appendChild(row_node)
  end
  
  it "should not open a paste in the browser if it wasn't truncated" do
    row_node = build do
      tr.message_123456! :class => "paste_message message user_123456" do
        td.person { span "Eloy D." }
        td.body do
          div do
            a :href => '/room/123456/paste/123456'
            
            br
            
            pre do
              code do
                'some code'
              end
            end
          end
        end
      end
    end
    
    handler.expects(:increase_badge_counter!)
    handler.expects(:growl_message).with('WebAppTestRoom', 'Eloy pasted: some code')
    
    @chat.appendChild(row_node)
  end
  
  it "should open a paste in the browser if it was truncated and the growl message is clicked" do
    row_node = build do
      tr.message_123456! :class => "paste_message message user_123456" do
        td.person { span "Eloy D." }
        td.body do
          div do
            a :href => '/room/123456/paste/123456'
            
            span.number_of_lines do
              span '86 more lines'
            end
            
            br
            
            pre do
              code do
                'some code'
              end
            end
          end
        end
      end
    end
    
    handler.expects(:increase_badge_counter!)
    handler.expects(:growl_message_and_open_url).with("Eloy: Truncated paste.", "#{BASE_URL}/room/123456/paste/123456")
    
    @chat.appendChild(row_node)
  end
  
  it "should be able to detect if a message includes any of the highlighted words" do
    handler.send(:includes_highlight_word?, 'foo bar baz').should.be false
    
    handler.preferences[:highlight_words] = 'bar bal'
    handler.send(:includes_highlight_word?, 'foo bar baz').should.be true
    handler.send(:includes_highlight_word?, 'foo bAr baz').should.be true
    handler.send(:includes_highlight_word?, 'foo barr baz').should.be false
    
    handler.preferences[:highlight_words] = "je m'apelle église".to_ns
    handler.send(:includes_highlight_word?, 'foo église baz'.to_ns).should.be true
    handler.send(:includes_highlight_word?, 'foo Église baz'.to_ns).should.be true
    handler.send(:includes_highlight_word?, 'foo eglise baz'.to_ns).should.be false
  end
  
  it "should use a sticky growl if a message includes one of the highlighted words" do
    handler.preferences[:highlight_words] = 'eloy'
    
    row_node = build do
      tr.message_123456! :class => "text_message message user_123456" do
        td.person { span "Someone E." }
        td.body { div "I'm talking to you Eloy!" }
      end
    end
    
    handler.expects(:sticky_growl_message_includes_highlight).times(1)
    handler.expects(:increase_badge_counter!).times(1)
    
    @chat.appendChild(row_node)
  end
  
  it "should open a link in the browser if a growl is clicked for a url only message" do
    url = "http://example.com/12345/bla?q=ja%20ja"
    
    row_node = build do
      tr.message_123456! :class => "text_message message user_123456" do
        td.person { span "Someone E." }
        td.body do
          a({ :href => url, :target => '_blank' }, url)
        end
      end
    end
    
    handler.expects(:growl_message_and_open_url).with("Someone: #{url}", url)
    handler.expects(:increase_badge_counter!)
    
    @chat.appendChild(row_node)
  end
  
  it "should send a enter/leave growl message when people enter the room" do
    row_node = build do
      tr.message_123456! :class => "enter_message message user_123456" do
        td.person { span "Someone E." }
        td.body { div "has entered the room" }
      end
    end
    
    handler.expects(:growl_entered_or_left).with("WebAppTestRoom", "Someone has entered the room")
    handler.expects(:increase_badge_counter!).times(0)
    
    @chat.appendChild(row_node)
  end
  
  it "should send a enter/leave growl message when people leave the room" do
    row_node = build do
      tr.message_123456! :class => "kick_message message user_123456" do
        td.person { span "Someone E." }
        td.body { div "has left the room" }
      end
    end
    
    handler.expects(:growl_entered_or_left).with("WebAppTestRoom", "Someone has left the room")
    handler.expects(:increase_badge_counter!).times(0)
    
    @chat.appendChild(row_node)
  end
  
  it "should modify the 'leave' link to actually follow the link and have a target set to '_close_tab'" do
    link = document.find(:first, '#leave_link a')
    link['href'].to_s.should.match /leave$/
    link['target'].to_s.should == '_close_tab'
    link['onclick'].to_s.should.not.match /return false;$/
  end
  
  private
  
  def build(&block)
    (@mb ||= NSMarkaby.new(document)).build(&block).to_a.first
  end
  
  def element(name)
    document.getElementById(name)
  end
  
  def document
    webView.mainFrame.DOMDocument
  end
  
  def html_for_fixture(name)
    File.read(File.expand_path("../../fixtures/#{name}.html", __FILE__))
  end
end
