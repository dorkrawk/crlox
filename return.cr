require "./lox_callable"

class Return < Exception
  getter value : Bool | Nil | Float64 | String | LoxCallable

  def initialize(value)
    super(nil)
    @value = value 
  end
end
