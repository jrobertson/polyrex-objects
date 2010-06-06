#!/usr/bin/ruby

# file: polyrex-objects.rb

require 'rexml/document'
require 'polyrex-createobject'

class PolyrexObjects
  include REXML
  
  def initialize(schema)

    a = schema.split('/')
    a.shift
    @class_names = []

    a.each do |x|
      name, raw_fields = x.split('[')
      if raw_fields then
        fields = raw_fields.chop.split(',').map &:strip
        @class_names << name.capitalize

        classx = []  
        classx << "class #{name.capitalize}"
        classx << "include REXML"
        classx << "def initialize(node, id=nil); @id=id; @node = node;  @create = PolyrexCreateObject.new('#{schema}'); end"
        fields.each do |field|
          classx << "def #{field}; XPath.first(@node, 'summary/#{field}/text()'); end"
          classx << "def #{field}=(text); XPath.first(@node, 'summary/#{field}').text = text; end"
        end
        classx << "end"

        eval classx.join("\n")
      end
    end

    # implement the child_object within each class object
    @class_names[0..-2].reverse.each_with_index do |class_name, k|    
      i = @class_names.length - (k + 1)
      eval "#{class_name}.class_eval { 
        def records()
          XPath.each(@node, 'records/*') {|record| yield(#{@class_names[i]}.new(record))}
        end

        def create(id=nil)
          @create.id = id || @id          
          @id = @id.to_i + 1
          @create.record = @node
          @create
        end
        
      }"
    end

   
  end

  def to_a
    @class_names.map {|x| eval(x)}
  end
  
  def to_h
    Hash[self.to_a.map {|x| [x.name[/\w+$/], x]}]
  end
  

end
