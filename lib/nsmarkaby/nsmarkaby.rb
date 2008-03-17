require File.expand_path("../tags", __FILE__)

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

class NSMarkaby
  class AttributeBuilder
    instance_methods.each { |meth| undef_method(meth) unless meth =~ /\A__/ }
    
    def initialize(elm, attrs, builder)
      @elm, @builder = elm, builder
      set_attributes(attrs)
    end
    
    def set_attributes(attrs)
      attrs.each { |k,v| @elm[k.to_s] = v }
    end
    
    def method_missing(mname, *args, &block)
      if mname.to_s =~ /(.+)\!$/
        @elm['id'] = $1
      else
        if klass = @elm['class']
          @elm['class'] = "#{klass} #{mname.to_s}"
        else
          @elm['class'] = mname.to_s
        end
      end
      
      @elm.innerHTML = args.last if args.last.is_a? String
      set_attributes(args.first) if args.first.is_a? Hash
      
      # set the `name` to the same as the id unless it's already set
      @elm['name'] = @elm['id'] if @elm.is_a? OSX::DOMHTMLInputElement and @elm['name'].nil? and @elm['id']
      
      @builder.do_block(@elm, &block) if block_given?
      
      # let the user chain calls
      self
    end
    
    # Called by interpolating an element.
    def to_s
      @builder.interpolated(@elm)
      @elm.outerHTML.to_s
    end
  end
  
  class Builder
    NSMarkaby::Tags::XHTMLStrict.tags.each do |tag|
      class_eval %{
        def #{tag}(*args, &block)
          define_tag(:#{tag}, *args, &block)
        end
      }
    end
    
    attr_reader :created_elements
    attr_reader :result
    
    def initialize(document, &block)
      @document = document
      @created_elements = []
      @result = instance_eval(&block)
      self
    end
    
    def to_s
      @created_elements.map { |elm| elm.outerHTML.to_s }.join
    end
    
    def define_tag(element_name, *args, &block)
      elm = @document.createElement(element_name.to_s)
      
      if args.last.is_a? String
        elm.innerHTML = args.last
      else
        do_block(elm, &block) if block_given?
      end
      
      @created_elements << elm
      
      attrs = args.first.is_a?(Hash) ? args.first : {}
      AttributeBuilder.new(elm, attrs, self)
    end
    
    def interpolated(element)
      @created_elements.delete(element)
    end
    
    def do_block(elm, &block)
      builder = Builder.new(@document, &block)
      unless builder.created_elements.empty?
        builder.created_elements.each { |child_elm| elm.appendChild(child_elm) }
      else
        elm.innerHTML = builder.result.to_s
      end
    end
    
    def to_a
      @created_elements
    end
  end
  
  def initialize(document)
    @document = document
  end
  
  def build(&block)
    Builder.new(@document, &block)
  end
end