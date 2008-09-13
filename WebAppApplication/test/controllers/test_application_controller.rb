require File.expand_path('../../test_helper', __FILE__)

class FooPreferencesController
end

describe 'ApplicationController, when initializing' do
  tests ApplicationController
  
  def after_setup
    OSX::NSBundle.mainBundle.stubs(:infoDictionary).returns('WebAppURL' => 'https://foo.example.com/login')
    @prefs = OSX::WebPreferences.standardPreferences
    controller.stubs(:setupTabBarController)
    controller.stubs(:addWebViewTab)
    WebApp::Plugins.stubs(:start)
  end
  
  it "should have set itself as the application delegate" do
    controller.awakeFromNib
    OSX::NSApp.delegate.should == controller
  end
  
  it "should register the default that we want the Shiira SRAutoFillManager to be enabled" do
    controller.awakeFromNib
    OSX::NSUserDefaults.standardUserDefaults['autoFillUserPass'].should == true.to_ns
  end
  
  it "should set the title of the main window to the url of this WebApp" do
    main_window.expects(:title=).with('foo.example.com/login')
    controller.awakeFromNib
  end
  
  it "should setup the tab view controller" do
    controller.expects(:setupTabBarController)
    controller.awakeFromNib
  end
  
  it "should load any available bundles" do
    controller.expects(:loadBundles)
    controller.awakeFromNib
  end
  
  it "should write out the user stylesheet and assign it to the WebPreferences" do
    stylesheet_path = '/path/to/stylesheet'
    WebApp::EventHandler.stubs(:write_tmp_stylesheet!).returns(stylesheet_path)
    
    @prefs.expects(:userStyleSheetEnabled=).with(true)
    @prefs.expects(:userStyleSheetLocation=).with do |url|
      url.path == stylesheet_path
    end
    
    controller.awakeFromNib
  end
  
  it "should assign a stylesheet to the WebPreferences, if there was none" do
    WebApp::EventHandler.stubs(:write_tmp_stylesheet!).returns(nil)
    @prefs.expects(:userStyleSheetEnabled=).times(0)
    controller.awakeFromNib
  end
  
  it "should add the first web view tab" do
    controller.expects(:addWebViewTab)
    controller.awakeFromNib
  end
  
  it "should start the plugins" do
    WebApp::Plugins.expects(:start)
    controller.awakeFromNib
  end
end

describe "ApplicationController, when loading bundles" do
  tests ApplicationController
  
  def after_setup
    controller.stubs(:require)
    Dir.stubs(:glob).returns([])
  end
  
  it "should load event handlers from bundles in Rucola::RCApp.root_path/bundles/" do
    event_handler = "#{Rucola::RCApp.root_path}/bundles/Foo.wabundle/event_handlers/foo_bar.rb"
    Dir.stubs(:glob).with("#{Rucola::RCApp.root_path}/bundles/*.wabundle/event_handlers/*.rb").returns([event_handler])
    
    controller.expects(:require).with(event_handler)
    controller.send(:loadBundles)
  end
  
  it "should load event handlers from bundles in Rucola::RCApp.application_support_path" do
    event_handler = "#{Rucola::RCApp.application_support_path}/Foo.wabundle/event_handlers/foo_bar.rb"
    Dir.stubs(:glob).with("#{Rucola::RCApp.application_support_path}/*.wabundle/event_handlers/*.rb").returns([event_handler])
    
    controller.expects(:require).with(event_handler)
    controller.send(:loadBundles)
  end
  
  it "should load window controllers from bundles in Rucola::RCApp.root_path/bundles/ and add a menu item for it" do
    window_controller = "#{Rucola::RCApp.root_path}/bundles/Foo.wabundle/controllers/foo_preferences_controller.rb"
    Dir.stubs(:glob).with("#{Rucola::RCApp.root_path}/bundles/*.wabundle/controllers/*.rb").returns([window_controller])
    
    controller.expects(:require).with(window_controller)
    bundlesMenu.expects(:addItem).with do |item|
      item.title == 'Foo Preferences...' and
      item.target == controller and
      item.action == 'openBundleWindowController:' and
      item.representedObject == FooPreferencesController
    end
    
    controller.send(:loadBundles)
  end
  
  it "should load window controllers from bundles in Rucola::RCApp.application_support_path and add a menu item for it" do
    window_controller = "#{Rucola::RCApp.application_support_path}/Foo.wabundle/controllers/foo_preferences_controller.rb"
    Dir.stubs(:glob).with("#{Rucola::RCApp.application_support_path}/*.wabundle/controllers/*.rb").returns([window_controller])
    
    controller.expects(:require).with(window_controller)
    bundlesMenu.expects(:addItem).with do |item|
      item.title == 'Foo Preferences...' and
      item.target == controller and
      item.action == 'openBundleWindowController:' and
      item.representedObject == FooPreferencesController
    end
    
    controller.send(:loadBundles)
  end
end