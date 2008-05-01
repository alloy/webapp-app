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
  
  it "should be possible to search with xpath" do
    div_node = build do
      div do
        p.bar 'foo'
        p 'bar'
        span do
          p 'baz1'
          p.baz 'baz2'
        end
      end
    end
    
    result = div_node.find_with_xpath('p[@class="bar"]')
    result.should.be.instance_of Array
    result.length.should.be 1
    
    result = div_node.find_with_xpath('p', :limit => :all)
    result.should.be.instance_of Array
    result.length.should.be 2
    
    result = div_node.find_with_xpath('p', :limit => :first)
    result.should.be.instance_of OSX::DOMHTMLParagraphElement
    result.innerText.should == 'foo'
    
    lambda {
      div_node.find_with_xpath('p', :limit => :limit)
    }.should.raise(ArgumentError)
  end
  
  it "should be possible to search with css" do
    div_node = build do
      div do
        p.bar 'foo'
        p 'bar'
        span do
          p 'baz1'
          p.baz 'baz2'
        end
      end
    end
    
    result = div_node.find_with_css('p.bar')
    result.should.be.instance_of Array
    result.length.should.be 1
    
    result = div_node.find_with_css('span p', :limit => :all)
    result.should.be.instance_of Array
    result.length.should.be 2
    
    result = div_node.find_with_css('p', :limit => :all)
    result.should.be.instance_of Array
    result.length.should.be 4
    
    result = div_node.find_with_css('p', :limit => :first)
    result.should.be.instance_of OSX::DOMHTMLParagraphElement
    result.innerText.should == 'foo'
    
    lambda {
      div_node.find_with_css('p', :limit => :limit)
    }.should.raise(ArgumentError)
  end
  
  it "should be possible to search to use the find() shortcut" do
    div_node = build do
      div do
        p.bar 'foo'
        p 'bar'
        span do
          p 'baz1'
          p.baz 'baz2'
        end
      end
    end
    
    result = div_node.find('p.bar')
    result.should.be.instance_of Array
    result.length.should.be 1
    
    result = div_node.find('span p')
    result.should.be.instance_of Array
    result.length.should.be 2
    
    result = div_node.find(:first, 'span p')
    result.should.be.instance_of OSX::DOMHTMLParagraphElement
    result.innerText.should == 'baz1'
    
    result = div_node.find(:xpath => 'span/p')
    result.should.be.instance_of Array
    result.length.should.be 2
    
    result = div_node.find(:first, :xpath => 'span/p')
    result.should.be.instance_of OSX::DOMHTMLParagraphElement
    result.innerText.should == 'baz1'
    
    lambda { div_node.find('p', 'span') }.should.raise(ArgumentError)
    lambda { div_node.find(:first, :all) }.should.raise(ArgumentError)
    lambda { div_node.find({}, {}) }.should.raise(ArgumentError)
  end
  
  it "should also be possible to use the #find method on a document" do
    @webView.mainFrame.DOMDocument.should.respond_to :find
    @webView.mainFrame.DOMDocument.should.respond_to :find_with_css
    @webView.mainFrame.DOMDocument.should.respond_to :find_with_xpath
  end
  
  it "should be possible to modify a link element to open in a new tab" do
    link = build { a }
    link.open_in_new_tab!
    link['target'].should == '_open_in_new_tab'
  end
  
  it "should be possible to modify a link element to close its tab" do
    link = build { a }
    link.close_tab!
    link['target'].should == '_close_tab'
  end
  
  private
  
  def build(&block)
    @mb.build(&block).to_a.first
  end
end