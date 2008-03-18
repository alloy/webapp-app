class OSX::DOMNode
  def [](key)
    if attr = attributes.getNamedItem(key)
      attr.value
    end
  end
  
  def []=(key, value)
    setAttribute__(key, value)
  end
  
  def appendChildren(children)
    children.each { |elm| appendChild elm }
  end
end

class OSX::DOMElement
  # Returns true or false indicating wether or not an element includes the given class.
  def class?(klass)
    if klasses = self['class']
      return klasses.split(' ').include?(klass)
    end
    false
  end
  
  # If the element responds to #children an array of the children is returned.
  def to_a
    if respondsToSelector('children')
      ary = []
      (0..(children.length - 1)).each { |idx| ary << children.item(idx) }
      ary
    else
      super
    end
  end
  
  # Performs an xpath query and returns the results in an array.
  def search(query)
    result = ownerDocument.evaluate_contextNode_resolver_type_inResult(query, self, nil, OSX::DOM_ANY_TYPE, nil)
    ary = []
    while node = result.iterateNext
      ary << node
    end
    ary
  end
end