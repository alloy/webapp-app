ENV['RUBYCOCOA_ENV'] = 'test'
ENV['RUBYCOCOA_ROOT'] = File.expand_path('../../', __FILE__)

require 'rubygems'
require 'test/unit'
require 'test/spec'
require 'mocha'
require 'rucola'
require 'rucola/test_helper'

require File.expand_path('../test_case', __FILE__)

require File.expand_path('../../config/boot', __FILE__)

require "lib/nsmarkaby/nsmarkaby"

# So OSX::NSApp works
module OSX
  class FakeApplication < NSObject
    attr_accessor :delegate
    
    def active?
      false
    end
  end
  NSApp = FakeApplication.alloc.init
end

# Otherwise the WebView rendering won't work.
Thread.new { OSX.CFRunLoopRun }

# Need to figure out how to make it store the actual cache, so the tests don't run too long each time.
#
# tmp_path = File.expand_path('../../../tmp', __FILE__)
# `mkdir -p #{tmp_path}` unless File.exist?(tmp_path)
# CACHE_SIZE = 20 * 1024 * 1024
# OSX::NSURLCache.sharedURLCache = OSX::NSURLCache.alloc.initWithMemoryCapacity_diskCapacity_diskPath(CACHE_SIZE, CACHE_SIZE, tmp_path)

module EventHandlerTestHelper
  # Returns the handler instance that's to be tested.
  def handler
    instance_to_be_tested
  end
  
  # Returns the WebView instance which is used during testing.
  def webView
    @webView ||= OSX::WebView.alloc.init
    handler.webView ||= @webView
    @webView
  end
  
  # Sets the url that the source represents and loads the given source in the WebView instance.
  # When it's done loading it will setup the event handler observers.
  #
  # The first time this is called for a url it can take some time to render.
  # But subsequent calls for the same url will be cached.
  def load_page(url, source)
    webView.mainFrame.loadHTMLString_baseURL(source, OSX::NSURL.URLWithString(url))
    sleep 0.25 while webView.loading?
    sleep 1
    handler.register_dom_observers!
  end
end
Test::Unit::TestCase.send(:include, EventHandlerTestHelper)

class Test::Spec::Should
  def differ(str, difference = 1)
    before = eval(str)
    @object.call
    eval(str).should == before + difference
  end
end

class Test::Spec::ShouldNot
  def differ(str)
    before = eval(str)
    @object.call
    eval(str).should == before
  end
end