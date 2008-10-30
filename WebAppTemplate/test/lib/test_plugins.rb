require File.expand_path('../../test_helper', __FILE__)

module WebApp::Plugins::TestPlugin
  class << self
    def plugin_arguments(klass, options)
    end
  end
end

class WebApp::EventHandler
  plugin :test_plugin
  plugin :test_plugin
end

describe "WebApp::Plugins" do
  include WebApp
  
  before do
    @test_plugin = WebApp::Plugins::TestPlugin
    @event_handler = WebApp::EventHandler
  end
  
  it "should inflect the proper module name from the symbol given" do
    WebApp::Plugins.expects(:const_defined?).with('TestPlugin').returns(true)
    @event_handler.plugin :test_plugin
  end
  
  it "should raise a NameError if the module inflected from the symbol given can't be found" do
    lambda do
      begin
        @event_handler.plugin :non_existant_test_plugin
      rescue NameError => exception
        
        exception.message.should == "The plugin module 'WebApp::Plugins::NonExistantTestPlugin' does not exist."
        
        raise exception
      end
    end.should.raise NameError
  end
  
  it "should include the module that was inflected from the symbol given" do
    @event_handler.expects(:include).with(@test_plugin)
    @event_handler.plugin :test_plugin
  end
  
  it "should pass the event handler class and any given options to the module" do
    @test_plugin.expects(:plugin_arguments).with(@event_handler, {})
    @event_handler.plugin :test_plugin
    
    @test_plugin.expects(:plugin_arguments).with(@event_handler, :foo => 'bar')
    @event_handler.plugin :test_plugin, :foo => 'bar'
  end
  
  it "should not try to pass any arguments to the module if the module doesn't want that" do
    @test_plugin.stubs(:respond_to?).with(:plugin_arguments).returns(false)
    @test_plugin.expects(:plugin_arguments).times(0)
    @event_handler.plugin :test_plugin
  end
  
  it "should add the plugin to WebApp::Plugins::included_plugins and only once" do
    WebApp::Plugins.included_plugins.select { |plugin| plugin == @test_plugin }.should == [@test_plugin]
  end
  
  it "should call start on each included plugin" do
    @test_plugin.expects(:start)
    WebApp::Plugins.start
  end
end