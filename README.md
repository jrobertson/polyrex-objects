#Introducing the Polyrex-Objects gem

The Polyrex-Objects gem is intended to be used internally by Polyrex only however it can be executed in isolation for testing purposes. In the example below the Polyrex-Objects gem is used to create an object as specified by the schema and populated with data from a Polyrex record represented as a Rexle element.

    require 'polyrex' 

    objects = PolyrexObjects.new('entities/section[name]/entity[name,count]').to_h 
    #=> {"Section"=>PolyrexObjects::Section, "Entity"=>PolyrexObjects::Entity}


    s =<<S
    <?polyrex schema="entities/entity[title,count]"?>
    Beans 34
    Juice 25
    S

    polyrex = Polyrex.new
    polyrex.parse s

    element = polyrex.element 'records/*'
    entity = objects['Entity'].new element

    entity.title
    #=> "Beans" 

    entity.count
    #=> "34" 

## Resources

* [jrobertson/polyrex-objects](https://github.com/jrobertson/polyrex-objects)
