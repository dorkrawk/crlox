class Environment
  @values = Hash(String, Bool | Nil | Float64 | String).new

  def define(name : String, value : Bool | Nil | Float64 | String)
    @values[name] = value
  end

  def get(name : Token) : Bool | Nil | Float64 | String
    if @values.has_key?(name.lexeme)
      return @values[name.lexeme]
    end
    
    raise LoxRuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
  end
end