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

class OSX::DOMNodeList
  # Returns the nodes in the list in an array.
  def to_a
    ary = []
    (0..(length - 1)).each { |idx| ary << item(idx) }
    ary
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
  
  def find(*args)
    options = { :limit => :all }
    options.merge!(args.pop) if args.last.is_a? Hash
    
    unless args.empty?
      case args.first
      when String
        if args.length == 1
          query = args.first
        else
          raise ArgumentError
        end
      when Symbol
        if args.length == 1
          options[:limit] = args.first
        elsif args.length == 2 and args.last.is_a?(String)
          options[:limit], query = args
        else
          raise ArgumentError
        end
      else
        raise ArgumentError
      end
    end
    
    options[:css] ||= query unless options[:xpath]
    
    if options[:xpath]
      find_with_xpath(options.delete(:xpath), options)
    else
      find_with_css(options.delete(:css), options)
    end
  end
  
  def find_with_xpath(query, options = {})
    options[:limit] ||= :all
    
    case options[:limit]
    when :all
      result = ownerDocument.evaluate_contextNode_resolver_type_inResult(query, self, nil, OSX::DOM_ANY_TYPE, nil)
      ary = []
      while node = result.iterateNext
        ary << node
      end
      ary
    when :first
      ownerDocument.evaluate_contextNode_resolver_type_inResult(query, self, nil, OSX::DOM_ANY_TYPE, nil).iterateNext
    else
      raise ArgumentError, "Non valid argument for options[:limit] was supplied: ':#{options[:limit]}'. Should be :all or :first."
    end
  end
  
  def find_with_css(query, options = {})
    options[:limit] ||= :all
    
    case options[:limit]
    when :all
      querySelectorAll(query).to_a
    when :first
      querySelector(query)
    else
      raise ArgumentError, "Non valid argument for options[:limit] was supplied: ':#{options[:limit]}'. Should be :all or :first."
    end
  end
  
end