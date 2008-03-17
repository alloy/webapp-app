require File.expand_path('../../test_helper', __FILE__)

describe "DOMNode" do
  before do
    @node = OSX::DOMNode.alloc.init
    @p_node = @node.createElement('p')
    @span_node = @p_node.createElement('span')
  end
  
  it "should have a search method which allows xpath queries" do
    @node.search("/p/span").should == @span_node
  end
  
  it "should have a hpricot like layer" do
    (@node/'p'/'span').should == @span_node
  end
end