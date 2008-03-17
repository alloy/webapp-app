require File.expand_path('../../test_helper', __FILE__)

require 'lib/dom_ext'
require "lib/nsmarkaby/nsmarkaby"

# describe "DOMNode" do
#   before do
#     @node = OSX::DOMNode.alloc.init
#     @p_node = @node.createElement('p')
#     @span_node = @p_node.createElement('span')
#   end
#   
#   it "should have a search method which allows xpath queries" do
#     @node.search("/p/span").should == @span_node
#   end
#   
#   it "should have a hpricot like layer" do
#     (@node/'p'/'span').should == @span_node
#   end
# end

describe "DOM Extensions" do
  before do
    @webView = OSX::WebView.alloc.init
    sleep 0.25 while @webView.loading?
    @mb = NSMarkaby.new(@webView.mainFrame.DOMDocument)
  end
  
  it "should be able to add multiple nodes as children at once" do
    tbl = build { table }
    rows = @mb.build do
      tr '1'
      tr '2'
    end.to_a
    tbl.appendChildren(rows)
    
    assert_equal '<table><tr>1</tr><tr>2</tr></table>', tbl.outerHTML.to_s
  end
  
  it "should be able to check if an elements classes includes a given one" do
    div1 = build { div.foo }
    div2 = build { div.foo.bar }
    div3 = build { div }
    
    div1.class?('foo').should.be true
    div2.class?('foo').should.be true
    div3.class?('foo').should.be false
    
    div1.class?('bar').should.be false
    div2.class?('bar').should.be true
    div3.class?('bar').should.be false
  end
  
  it "should be possible to get an array of the children of an element" do
    div_node = build do
      div do
        p 'foo'
        p 'bar'
      end
    end
    
    div_node.to_a.should == [div_node.children.item(0), div_node.children.item(1)]
  end
  
  private
  
  def build(&block)
    @mb.build(&block).to_a.first
  end
end