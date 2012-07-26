#!/usr/bin/env ruby

# file: polyrex-objects.rb


require 'polyrex-createobject'
require 'rexle'


class PolyrexObjects

  class PolyrexObject
    
    def initialize(node, id='0')
      @@id = id
      @node = node
    end
    
    def create(id=nil)
      id ||= @@id 
      id.succ!
      @create.id = id         

      @create.record = @node.element('records')
      @create
    end    

    def to_xml(options={})
      @node.xml(options)
    end
    
    def with()
      yield(self)
    end
  end
  
  def initialize(schema, id='0', node=nil)

    @node = node
    @@id = id

    if schema then
      a = schema.split('/')
      a.shift
      @class_names = []

      a.each do |x|
        name, raw_fields = x.split('[')
        if raw_fields then
          fields = raw_fields.chop.split(',').map &:strip
          @class_names << name.capitalize

          classx = []  
          classx << "class #{name.capitalize} < PolyrexObject"
          classx << "def initialize(node=nil, id='0')"
          classx << "super(node,id)"
          classx << "@create = PolyrexCreateObject.new('#{schema}', @@id)"
          classx << "end"
          fields.each do |field|
            classx << "def #{field}; @node.element('summary/#{field}/text()'); end"
            classx << "def #{field}=(text); @node.element('summary/#{field}').text = text; end"
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
            objects = @node.xpath('records/*').map {|record| #{@class_names[i]}.new(record, @@id)}

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
                  
          alias #{@class_names[i].downcase} records
          
        }"
      end
      
      @class_names[1..-1].each_with_index do |class_name, k|    
        eval "#{class_name}.class_eval {        
          def parent()
            #{@class_names[k]}.new(@node.parent.parent, @@id)
          end                
        }"
      end
      
      methodx = @class_names.map do |name|
        %Q(def #{name.downcase}(); #{name}.new(@node, @@id); end)
      end
      
      self.instance_eval(methodx.join("\n"))
    end
  end

  def to_a
    @class_names.map {|x| eval(x)}
  end
  
  def to_h
    Hash[self.to_a.map {|x| [x.name[/\w+$/], x]}]
  end
  

end
