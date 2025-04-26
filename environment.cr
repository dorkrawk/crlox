class Environment
  getter values = Hash(String, Bool | Nil | Float64 | String | LoxCallable).new
  getter enclosing : Environment?

  def initialize(enclosing : Environment? = nil)
    @enclosing = enclosing
  end

  def define(name : String, value : Bool | Nil | Float64 | String | LoxCallable)
    @values[name] = value
  end

  def ancestor(distance : Int32)
    environment = self
    distance.times do
      environment = environment.try &.enclosing
    end

    environment
  end

  def get_at(distance : Int32, name : String)
    ancestor(distance).try &.values[name]
  end

  def assign_at(distance : Int32, name : Token, value : Bool | Nil | Float64 | String | LoxCallable)
    ancestor(distance).try &.values[name.lexeme] = value
  end

  def get(name : Token) : Bool | Nil | Float64 | String | LoxCallable
    if @values.has_key?(name.lexeme)
      return @values[name.lexeme]
    end

    if @enclosing
      return @enclosing.try &.get(name)
    end

    pp "values: #{@values}"
    pp "enclosing: #{@enclosing}"
    
    raise LoxRuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
  end

  def assign(name : Token, value : Bool | Nil | Float64 | String | LoxCallable)
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
