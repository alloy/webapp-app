require File.expand_path('../../test_helper', __FILE__)

require "lib/dom_ext"
require "lib/nsmarkaby/nsmarkaby"

describe "NSMarkaby" do
  before do
    html = %{
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html>
</html>
    }
    @webView = OSX::WebView.alloc.init
    @webView.mainFrame.loadHTMLString_baseURL(html, OSX::NSURL.URLWithString("http://example.com"))
    sleep 0.25 while @webView.loading?
    
    @mb = NSMarkaby.new(@webView.mainFrame.DOMDocument)
  end
  
  it "should initialize" do
    @mb.should.be.instance_of NSMarkaby
  end
  
  it "should be able to build" do
    span_contents = 'span contents'
    
    mab do
      table do
        tr do
          span do
            span_contents
          end
        end
        tr do
          div do
            p 'div contents'
          end
        end
      end
    end.should == '<table><tr><span>span contents</span></tr><tr><div><p>div contents</p></div></tr></table>'
  end
  
  def test_simple
    assert_equal('<table></table>', mab { table })
  end
  
  def test_classes_and_ids
    assert_equal %{<div class="one"></div>}, mab { div.one '' }
    assert_equal %{<div class="one two"></div>}, mab { div.one.two '' }
    assert_equal %{<div id="three"></div>}, mab { div.three! '' }
    assert_equal %{<hr class="hidden">}, mab { hr.hidden }
    assert_equal %{<input class="foo" id="bar" name="bar">}, mab { input.foo :id => 'bar' }
    assert_equal %{<div class="bar" id="foo" name="baz">bla</div>}, mab { div.bar.foo!({:name => 'baz'}, 'bla') }
    assert_equal %{<div class="bar" id="foo" name="baz">bla</div>}, mab { div.bar.foo!({:name => 'baz'}) { 'bla' } }
  end
  
  def test_interpolation
    assert_equal '<div>foo <strong>bar</strong> baz</div>', mab { div { "foo #{ strong "bar" } baz" } }
    assert_equal '<div>foo <strong>bar</strong> baz</div>', mab { div { "foo #{ strong { "bar" } } baz" } }
  end
  
  def test_fragments
    assert_equal %{<div><h1>Monkeys</h1><h2>Giraffes <small>Miniature</small> and <strong>Large</strong></h2><h3>Donkeys</h3><h4>Parakeet <b><i>Innocent IV</i></b> in Classic Chartreuse</h4></div>}, 
        mab { div { h1 "Monkeys"; h2 { "Giraffes #{small 'Miniature' } and #{strong 'Large'}" }; h3 "Donkeys"; h4 { "Parakeet #{b { i 'Innocent IV' }} in Classic Chartreuse" } } }
    assert_equal %{<div><h1>Monkeys</h1><h2>Giraffes <strong>Miniature</strong></h2><h3>Donkeys</h3></div>}, 
        mab { div { h1 "Monkeys"; h2 { "Giraffes #{strong 'Miniature' }" }; h3 "Donkeys" } }
  end
  
  private
  
  def mab(&block)
    @mb.build(&block).to_s
  end
end

describe "DOMElement extensions" do
  it "should check if an element is of a specific class" do
    
  end
end