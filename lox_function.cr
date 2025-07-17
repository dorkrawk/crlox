require "./lox_callable"
require "./stmt"
require "./environment"
require "./return"

class LoxFunction < LoxCallable
  def initialize(declaration : Stmt::Function, closure : Environment, is_initializer : Bool)
    @closure = closure
    @declaration = declaration
    @is_initializer = is_initializer
  end

  def bind(instance : LoxInstance)
    environment = Environment.new(@closure)
    environment.define("this", instance)

    LoxFunction.new(@declaration, environment, @is_initializer)
  end
  
  def call(interpreter, arguments)
    environment = Environment.new(@closure)
    @declaration.params.each_with_index do |param, i|
      environment.define(param.lexeme, arguments[i])
    end

    begin
      interpreter.execute_block(@declaration.body, environment)
    rescue return_value : Return
      return @closure.get_at(0, "this") if @is_initializer

      return return_value.value
    end

    return @closure.get_at(0, "this") if @is_initializer
    
    nil
  end

  def arity
    @declaration.params.size
  end

  def to_s
    "<fn #{declaration.name.lexeme}>"
  end
end
