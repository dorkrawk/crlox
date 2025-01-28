class Environment
  @values = Hash(String, Bool | Nil | Float64 | String).new
  @enclosing : Environment?

  def initialize(enclosing : Environment? = nil)
    @enclosing = enclosing
  end

  def define(name : String, value : Bool | Nil | Float64 | String)
    @values[name] = value
  end

  def get(name : Token) : Bool | Nil | Float64 | String
    if @values.has_key?(name.lexeme)
      return @values[name.lexeme]
    end

    if @enclosing
      return @enclosing.try &.get(name)
    end
    
    raise LoxRuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
  end

  def assign(name : Token, value : Bool | Nil | Float64 | String)
    if @values.has_key?(name.lexeme)
      @values[name.lexeme] = value
      return
    end

    if @enclosing
      @enclosing.try &.assign(name, value)
      return
    end

    raise LoxRuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
  end
end