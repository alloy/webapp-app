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
  end
  
  it "should parse the name of the room on page loaded" do
    assigns(:room_name).should == 'WebAppTestRoom'
  end
  
  it "should detect that a new message has been posted in the channel" do
    row = build do
      tr.message_123456! :class => "text_message message user_123456" do
        td.person { span "Eloy D." }
        td.body { div "Hello world!" }
      end
    end
    
    handler.expects(:growl_channel_message).with('WebAppTestRoom', "Eloy: Hello world!")
    handler.expects(:increase_badge_counter!)
    
    chat = element('chat')
    chat.appendChild(row)
  end
  
  it "should not do anything if a message is from the user" do
    row = build do
      tr.message_123456! :class => "text_message message user_123456 you" do
        td.person { span "Eloy D." }
        td.body { div "Hello world!" }
      end
    end
    
    handler.expects(:growl_channel_message).times(0)
    handler.expects(:increase_badge_counter!).times(0)
    
    chat = element('chat')
    chat.appendChild(row)
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
