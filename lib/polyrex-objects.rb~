#!/usr/bin/env ruby

# file: polyrex-objects.rb


require 'polyrex-createobject'
require 'rexle'


class PolyrexObjects


  class PolyrexObject

    attr_reader :node, :id

    def initialize(node, id: '0')
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

    def count()
      self.records.length
    end

    def create(id: '0')
      id ||=@@id

      id.succ!
      @create.id = id         

      @create.record = @node.element('records')
      @create
    end    

    def delete()
      @node.delete
    end

    def deep_clone()
      self.class.new Rexle.new(self.to_xml).root
    end

    def element(xpath)
      @node.element(xpath)
    end

    def id()
      @node.attributes[:id]
    end

    def inspect()
      "#<PolyrexObject:%s" % __id__
    end

    def [](n)
      self.records[n]
    end
    
    def to_doc()
      Rexle.new @node.to_a
    end

    def to_dynarex()

      root = Rexle.new(self.to_xml).root

      summary = root.element('summary')
      e = summary.element('schema')
      child_schema = root.element('records/*/summary/schema/text()')\
                                            .sub('[','(').sub(']',')')
      e.text = "%s/%s" % [e.text, child_schema]
      summary.delete('format_mask')
      summary.element('recordx_type').text = 'dynarex'

      summary.add root.element('records/*/summary/format_mask').clone
      root.xpath('records/*/summary/format_mask').each(&:delete)

xsl_buffer =<<EOF
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output encoding="UTF-8"
            indent="yes"
            omit-xml-declaration="yes"/>

  <xsl:template match="*">
    <xsl:element name="{name()}">
    <xsl:element name="summary">
      <xsl:for-each select="summary/*">
        <xsl:copy-of select="."/>
      </xsl:for-each>
    </xsl:element>
    <xsl:element name="records">
      <xsl:for-each select="records/*">
        <xsl:element name="{name()}">
          <xsl:copy-of select="summary/*"/>
        </xsl:element>
      </xsl:for-each>
    </xsl:element>
    </xsl:element>
  </xsl:template>
</xsl:stylesheet>
EOF
      xslt  = Nokogiri::XSLT(xsl_buffer)
      buffer = xslt.transform(Nokogiri::XML(root.xml)).to_s
      Dynarex.new buffer

    end


    def to_h()
      @fields.inject({}) do |r, field|
        r.merge(field.capitalize => self.method(field).call)
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
  
  def initialize(schema, node=nil, id: '0')

    @node = node
    @@id = id

    @schema = schema

    if schema then
  
      @class_names = []

      h = PolyrexSchema.new(schema).to_h
  
      scan = -> (a) do
        a.each do |x|
          make_class(x[:name], x[:fields], x[:schema])
          scan.call(x[:children]) if x[:children]
        end
      end

      scan.call h

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
            #{@class_names[k]}.new(@node.parent.parent, id: @@id)
          end                
        }"
      end
      
      methodx = @class_names.map do |name|
        %Q(def #{name.downcase}(); #{name}.new(@node, id: @@id); end)
      end
      
      self.instance_eval(methodx.join("\n"))
    end
  end

  def to_a
    @class_names.map {|x| eval(x.to_s)}
  end
  
  def to_h
    Hash[self.to_a.map {|x| [x.name[/\w+$/], x]}]
  end
  
  private

  def make_class(name, fields, schema=@schema)

    if fields then

      @class_names << name.capitalize

      classx = []  
      classx << "class #{name.capitalize} < PolyrexObject"
      classx << "def initialize(node=nil, id: '0')"
      classx << "  @id = id"
      classx << "  node ||= Rexle.new('<#{name}><summary/><records/></#{name}>').root"
      classx << "  super(node, id: id)"

      classx << "  a = node.xpath('summary/*',&:name)"
      classx << "  yaml_fields = a - (#{fields}  + %w(format_mask))"
      classx << "yaml_fields.each do |field|"
      classx << %q( "def self.#{field})
      classx << %q(    s = @node.element('summary/#{field}/text()'))
      classx << %q(    s[/^---/] ? YAML.load(s) : s)
      classx << %q(  end")
      classx << "end"

      classx << "@fields = %i(#{fields.join(' ')})"          
      classx << "@create = PolyrexCreateObject.new('#{@schema[/\/(.*)/,1]}', id: '#{@id}')"
      classx << "end"

      fields.each do |field|
        classx << "def #{field}"
        classx << "  if @node.element('summary/#{field}').nil? then"
        classx << "    @node.element('summary').add Rexle::Element.new('#{field}')"
        classx << "  end"
        classx << "  node = @node.element('summary/#{field}/text()')"
        classx << "  node ? node.clone : ''"
        classx << "end"
        classx << "def #{field}=(text)"
        classx << "  if @node.element('summary/#{field}').nil? then"
        classx << "    @node.element('summary').add Rexle::Element.new('#{field}', value: text)"
        classx << "  else"
        classx << "    @node.element('summary/#{field}').text = text"
        classx << "  end"
        classx << "end"
      end

      classx << "end"          

      eval classx.join("\n")
    end
  end

  def make_def_records(class_name, i=0)

    eval "#{class_name}.class_eval { 
      def records()

        classes = {#{@class_names.map{|x| %Q(%s: %s) % [x[/[^:]+$/].downcase,x]}.join(',')} }

        objects = @node.xpath('records/*').map do |record| 
          classes[record.name.to_sym].new(record, id: '#{@@id}')
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



end