require File.expand_path('../../test_helper', __FILE__)

OSX::NSApplication.sharedApplication

GROWL_OPTIONS = { :entered => 'Someone has entered', :leave => 'Someone has left' }

class GrowlTestEventHandler < WebApp::EventHandler
  plugin :growl, GROWL_OPTIONS.merge(:message => 'A new message')
end

class GrowlTestEventHandler2 < WebApp::EventHandler
  plugin :growl, GROWL_OPTIONS
end

class Growl::Notifier
  def register(*args)
  end
end

WebApp::Plugins::Growl.start

describe "WebApp::Plugins::Growl" do
  before do
    @growl_plugin = WebApp::Plugins::Growl
  end
  
  it "should have been added to WebApp::Plugins.included_plugins" do
    WebApp::Plugins.included_plugins.should.include @growl_plugin
  end
  
  it "should have stored the notifications that were specified in the plugin arguments" do
    @growl_plugin.registered_notifications[GrowlTestEventHandler2].should == GROWL_OPTIONS
  end
  
  it "should define shortcut methods for the specified growl notifications" do
    [GrowlTestEventHandler, GrowlTestEventHandler2].each do |klass|
      methods = klass.instance_methods
      
      methods.should.include 'growl'
      methods.should.include 'growl_entered'
      methods.should.include 'growl_leave'
      methods.should.include 'sticky_growl'
      methods.should.include 'sticky_growl_entered'
      methods.should.include 'sticky_growl_leave'
    end
  end
  
  it "should have a list of all notification names" do
    @growl_plugin.notification_names.should == ['A new message', 'Someone has entered', 'Someone has left'].to_set
  end
  
  it "should have registered the notification names with the Growl bridge" do
    Rucola::RCApp.stubs(:app_name).returns('Campfire')
    growl = Growl::Notifier.sharedInstance
    growl.expects(:register).with(:Campfire, ['A new message', 'Someone has entered', 'Someone has left'])
    @growl_plugin.start
  end
end

describe "WebApp::Plugins::Growl, when growling" do
  before do
    OSX::NSDistributedNotificationCenter.defaultCenter.stubs(:postNotificationName_object_userInfo_deliverImmediately)
    @callbacks = {}
    Growl::Notifier.sharedInstance.instance_variable_set(:@callbacks, @callbacks)
    
    @event_handler = GrowlTestEventHandler.alloc.init
    @args = ['Someone has entered', 'Title', 'Description', { :sticky => true }]
  end
  
  it "should pass the growl on to the Growl::Notifier::sharedInstance" do
    Growl::Notifier.sharedInstance.expects(:notify).with(*@args).times(1)
    @event_handler.growl(*@args)
  end
  
  it "should not pass the notification on if the application is active" do
    OSX::NSApp.stubs(:active?).returns(true)
    
    Growl::Notifier.sharedInstance.expects(:notify).with(*@args).times(0)
    @event_handler.growl(*@args)
  end
  
  it "should still pass the notification on in a debug build, even if the application is active" do
    Rucola::RCApp.stubs(:debug?).returns(true)
    OSX::NSApp.stubs(:active?).returns(true)
    
    Growl::Notifier.sharedInstance.expects(:notify).with(*@args).times(1)
    @event_handler.growl(*@args)
  end
  
  it "should send a sticky growl" do
    @event_handler.expects(:growl).with(*@args)
    @args.pop
    @event_handler.sticky_growl(*@args)
  end
  
  it "should send a growl from a shortcut method" do
    @args.pop
    @event_handler.expects(:growl).with(*@args)
    @event_handler.growl_entered('Title', 'Description')
  end
  
  it "should send a sticky growl from a shortcut method" do
    @event_handler.expects(:growl).with(*@args)
    @event_handler.sticky_growl_entered('Title', 'Description')
  end
  
  it "should send a callback along with a growl" do
    should_call_block "@event_handler.growl(*@args)"
  end
  
  it "should send a callback along with a growl shortcut" do
    should_call_block "@event_handler.sticky_growl_entered('Title', 'Description')"
  end
  
  private
  
  def should_call_block(str)
    called = false
    eval "#{str} { called = true }"
    @callbacks.length.should.be 1
    
    @callbacks.to_a.first.last.call
    called.should.be true
  end
end