#!/usr/bin/env ruby

# file: polyrex-objects.rb


require 'polyrex-createobject'
require 'rexle'


class PolyrexObjects

  class PolyrexObject

    attr_reader :node    

    def initialize(node, id='0')
      @@id = id
      @node = node
      @fields =[]
    end
    
    def add(pxobj)
      @node.element('records').add pxobj.node
    end

    def clone()
      self.class.new Rexle.new(self.node.to_a).root
    end

    def create(id=nil)
      id ||= @@id 
      id.succ!
      @create.id = id         

      @create.record = @node.element('records')
      @create
    end    

    def delete()
      @node.delete
    end

    def element(xpath)
      @node.element(xpath)
    end

    def inspect()
      "#<PolyrexObject:%s" % __id__
    end

    def to_h()
      @fields.inject({}) do |r, field|
        r.merge(field => self.method(field).call)
      end
    end

    def to_xml(options={})
      @node.xml(options)
    end
    
    def with()
      yield(self)
    end

    def xpath(s)
      @node.xpath(s)
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

          classx << "a = node.xpath('summary/*',&:name)"
          classx << "yaml_fields = a - (#{fields}  + %w(format_mask))"
          classx << "yaml_fields.each do |field|"
          classx << %q(instance_eval "def #{field}; YAML.load(@node.element('summary/#{field}/text()')); end")
          classx << "end"

          classx << "@fields = %i(#{fields.join(' ')})"          
          classx << "@create = PolyrexCreateObject.new('#{schema}', @@id)"
          classx << "end"

          fields.each do |field|
            classx << "def #{field}"
            classx << "  if @node.element('summary/#{field}').nil? then"
            classx << "    @node.element('summary').add Rexle::Element.new('#{field}')"
            classx << "  end"
            classx << "  @node.element('summary/#{field}/text()').clone"
            classx << "end"
            classx << "def #{field}=(text)"
            classx << "  if @node.element('summary/#{field}').nil? then"
            classx << "    @node.element('summary').add Rexle::Element.new('#{field}', text)"
            classx << "  else"
            classx << "    @node.element('summary/#{field}').text = text"
            classx << "  end"
            classx << "end"
          end

          classx << "end"          

          eval classx.join("\n")
        end
      end

      if @class_names.length < 2 then
        make_def_records(@class_names.first)
      else
        # implement the child_object within each class object
        @class_names[0..-2].reverse.each_with_index do |class_name, k|    

          i = @class_names.length - (k + 1)
          make_def_records(class_name,i)
        end
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

  def make_def_records(class_name, i=0)

    eval "#{class_name}.class_eval { 
      def records()

        classes = {#{@class_names.map{|x| %Q(%s: %s) % [x[/[^:]+$/].downcase,x]}.join(',')} }

        objects = @node.xpath('records/*').map do |record| 
          classes[record.name.to_sym].new(record, @@id)
        end

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

        def objects.remove_all()
          e = @node.element('records')
          e.insert_before Rexle::Element.new('records')
          e.delete
        end

        objects
      end        
              
      alias #{@class_names[i].downcase} records
      
    }"

  end

  def to_a
    @class_names.map {|x| eval(x)}
  end
  
  def to_h
    Hash[self.to_a.map {|x| [x.name[/\w+$/], x]}]
  end
  

end