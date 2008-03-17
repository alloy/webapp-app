require File.expand_path('../../test_helper', __FILE__)

require "lib/event_handlers/campfire"

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
    load_page "#{BASE_URL}/room/144516", html_for_fixture('campfire_room')
    
    @chat = element('chat')
  end
  
  it "should parse the name of the room on page loaded" do
    assigns(:room_name).should == 'WebAppTestRoom'
  end
  
  it "should detect that a new message has been posted in the channel" do
    row_node = build do
      tr.message_123456! :class => "text_message message user_123456" do
        td.person { span "Eloy D." }
        td.body { div "Hello world!" }
      end
    end
    
    handler.expects(:growl_channel_message).with('WebAppTestRoom', "Eloy: Hello world!")
    handler.expects(:increase_badge_counter!)
    
    @chat.appendChild(row_node)
  end
  
  it "should only handle nodes which are table row nodes" do
    div_node = build { div "whatever" }
    
    handler.expects(:growl_channel_message).times(0)
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
    
    handler.expects(:growl_channel_message).times(0)
    handler.expects(:increase_badge_counter!).times(0)
    
    @chat.appendChild(row_node)
  end
  
  it "should not do anything for timestamp messages" do
    row_node = build do
      tr.message_123456! :class => "timestamp_message message"
    end
    
    handler.expects(:growl_channel_message).times(0)
    handler.expects(:increase_badge_counter!).times(0)
    
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
    handler.expects(:growl_channel_message).with do |room, message, proc|
      room == 'WebAppTestRoom' and message == "Eloy: Truncated paste:\n86 more linessome code" and proc.is_a?(Proc)
    end
    
    @chat.appendChild(row_node)
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
    File.read(File.expand_path("../fixtures/#{name}.html", __FILE__))
  end
end
