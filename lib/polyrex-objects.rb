#!/usr/bin/ruby

# file: polyrex-objects.rb

class PolyrexObjects
  def initialize(schema)

    a = schema.split('/')
    a.shift
    @class_names = []

    a.each do |x|
      name, raw_fields = x.split('[')
      fields = raw_fields.chop.split(',').map &:strip
      @class_names << name.capitalize

      classx = []  
      classx << "class #{name.capitalize}"
      classx << "def initialize(node); @node = node; end"
      fields.each do |field|
        classx << "def #{field}; XPath.first(@node, 'summary/#{field}/text()'); end"
      end
      classx << "end"

      eval classx.join("\n")
    end

  end

  def to_a
    @class_names.map {|x| eval(x)}
  end
  
  def to_h
    Hash[self.to_a.map {|x| [x.name[/\w+$/], x]}]
  end
end
