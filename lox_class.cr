require "./lox_callable"
require "./lox_instance"

class LoxClass < LoxCallable
  
  def initialize(name : String, superclass : LoxClass?, methods : Hash(String, LoxFunction))
    @name = name
    @superclass = superclass
    @methods = methods
  end

  def find_method(name : String)
    if @methods.has_key?(name)
      return @methods[name]
    end

    if !@superclass.nil?
      return @superclass.try &.find_method(name)
    end

    return nil
  end

  def to_s
    name
  end

  def call(interpreter, arguments)
    instance = LoxInstance.new(self)
    initializer = find_method("init")
    initializer.bind(instance).call(interpreter, arguments) if !initializer.nil?

    instance
  end

  def arity
    initializer = find_method("init")
    return 0 if initializer.nil?
    
    return initializer.arity
  end
end
