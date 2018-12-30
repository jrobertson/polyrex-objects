#!/usr/bin/env ruby

# file: polyrex-objects.rb


require 'polyrex-createobject'
require 'rexle'


class PolyrexObjects

  class PolyrexObject
    
    attr_reader :node, :id

    def initialize(node, id: '0', debug: false)

      @id = id
      @fields =[]
      @node, @debug = node, debug

      if node then
        
        e = node.element('summary')
        @schema = e.text('schema')
        @child_schema = @schema =~ /\// ? @schema[/(?<=\/).*/] : @schema
        puts '@child_schema:' + @child_schema.inspect if @debug
        @record = @schema[/^[^\[]+/]
        @fields = @schema[/(?<=\[)[^\]]+/].split(/ *, */)
        
        attr = @fields.map {|x| [x, e.text(x)] }
        build_attributes attr

        define_singleton_method(@record.to_sym) { self.records}
        
      end

    end

    def add(pxobj)
      @node.element('records').add pxobj.node
    end
    
    
    def at_css(s)
      @node.at_css s
    end
    
    def attributes()
      @node.attributes
    end

    def clone()
      self.class.new Rexle.new(self.node.to_a).root
    end

    def count()
      self.records.length
    end

    def create(id: @id)      

      PolyrexCreateObject.new(id: id, record: @node)
    end
    
    def css(s)
      @node.css s
    end

    def delete()
      @node.delete
    end

    def deep_clone()
      self.class.new Rexle.new(self.to_xml).root
    end
    
    def each_recursive(parent=self, level=0, &blk)
      
      parent.records.each.with_index do |x, index|

        blk.call(x, parent, level, index) if block_given?

        each_recursive(x, level+1, &blk) if x.records.any?
        
      end
      
    end      

    def element(xpath)
      @node.element(xpath)
    end

    def id()
      @node.attributes[:id]
    end

    def inspect()
      "#<%s:%s" % [self.class.name, __id__]
    end

    def [](n)
      self.records[n]
    end
    
    def parent()

      parent_node = self.node.parent.parent

      Kernel.const_get(parent_node.name.capitalize)\
        .new(parent_node, id: parent_node.attributes[:id])

    end
    
    def parent?()
      
      # if the node is at the 1st level of records it will not have a 
      # PolyrexObject parent
      
      node.parent.parent.parent.parent ? true : false
    end

    def records()

      @node.xpath('records/*').map do |node|
        Kernel.const_get(node.name.capitalize).new node
      end

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
      summary.delete('recordx_type')

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


      begin
        rexslt = Rexslt.new(xsl_buffer, root.xml)
        buffer = rexslt.to_s
      rescue
        puts ($!).inspect
        exit
      end

      r = Dynarex.new buffer
      r

    end

    def to_h()
      @fields.inject({}) do |r, field|
        r.merge(field=> self.method(field).call)
      end
    end

    def to_s()
      
      if self.respond_to? :records then
        
        build(self.records).join("\n")
        
      else

        summary = self.element 'summary'
        format_mask = summary.text('format_mask').to_s
        format_mask.gsub(/\[![^\]]+\]/){|x| summary.text(x[2..-2]).to_s}
        
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

    private

    def build_attributes(attr=[])

      attr.each do |name, value|

        var = name.to_s
        get, set = var.to_sym, (var + '=').to_sym

        define_singleton_method(get) do
          @node.element("summary/#{__callee__}/text()").to_s
        end

        define_singleton_method(set) do |v|
          @node.element("summary/#{(__callee__).to_s.chop}").text = v.to_s
        end

      end

    end

    def build(records, indent=0)

      records.map do |item|

        summary = item.element 'summary'
        format_mask = summary.text('format_mask').to_s
        line = format_mask.gsub(/\[![^\]]+\]/){|x| summary.text(x[2..-2]).to_s}

        records = item.element('records').elements.to_a
        
        if records.length > 0 then
          line = line + "\n" + build(records, indent + 1).join("\n") 
        end
        ('  ' * indent) + line
      end
    end   

  end

  def initialize(schema, debug: false)

    @debug = debug
    record_names = schema.scan(/(?<=\/)\w+/)
    puts 'record_names: ' + record_names.inspect if @debug

    @classes = record_names.inject({}) do |r, name|
      puts 'name: ' + name.inspect if @debug
      r.merge!({name.to_sym => \
                (Object.const_set name.capitalize, Class.new(PolyrexObject))})
    end

  end

  def to_h
    @classes
  end

  def to_a
    @classes.to_a
  end
end
