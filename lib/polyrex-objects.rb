#!/usr/bin/ruby

# file: polyrex-objects.rb

require 'polyrex-createobject'
require 'rexle'

class PolyrexObjects
  
  def initialize(schema, node=nil, id=nil)

    @node = node
    @id = id
    
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
        classx << "def initialize(node, id=nil)"
        classx << "@id=id; @node = node;"
        classx << "@create = PolyrexCreateObject.new('#{schema}')"
        classx << "end"
        fields.each do |field|
	  classx << "def #{field}; @node.element('summary/#{field}/text()'); end"
	  classx << "def #{field}=(text); @node.element('summary/#{field}').text = text; end"
        end
        classx << "def to_xml(options={}); @node.xml(options); end"
        classx << "def with(); yield(self); end"
        classx << "end"

        eval classx.join("\n")
      end
    end

    # implement the child_object within each class object
    @class_names[0..-2].reverse.each_with_index do |class_name, k|    
      i = @class_names.length - (k + 1)
      eval "#{class_name}.class_eval { 
        def records()
	  objects = @node.xpath('records/*').map {|record| #{@class_names[i]}.new(record)}

          def objects.records=(node); @node = node; end
          def objects.records(); @node; end

          def objects.sort_by!(&element_blk)
	    a = @node.xpath('records/*').sort_by &element_blk
	    records = @node.xpath('records')
            records.delete
            records = Rexle::Element.new 'records'
            a.each {|record| records.add record}
            @node.add records
            @node.xpath('records/*').map {|record| #{@class_names[i]}.new(record)}
          end

          objects.records = @node
          objects
        end        

        def create(id=nil)
          @create.id = id || @id          
          @id = @id.to_i + 1
          @create.record = @node
          @create
        end
                
        alias #{@class_names[i].downcase} records
        
      }"
    end
    
    @class_names[1..-1].each_with_index do |class_name, k|    
      eval "#{class_name}.class_eval {        
        def parent()
          #{@class_names[k]}.new(@node.parent.parent)
        end                
      }"
    end
    
    methodx = @class_names.map do |name|
      %Q(def #{name.downcase}(); #{name}.new(@node, @id); end)
    end
    
    self.instance_eval(methodx.join("\n"))

   
  end

  def to_a
    @class_names.map {|x| eval(x)}
  end
  
  def to_h
    Hash[self.to_a.map {|x| [x.name[/\w+$/], x]}]
  end
  

end
