class LoxInstance

  def initialize(klass : LoxClass)
    @klass = klass
    @fields = Hash(String, LoxObject).new
  end

  def get(name : Token)
    if @fields.has_key?(name.lexeme)
      return @fields[name.lexeme]
    end

    method = @klass.find_method(name.lexeme)
    return method.bind(self) if !method.nil?

    raise LoxRuntimeError.new(name, "Undefined property '#{name.lexeme}'.")
  end

  def set(name : Token, value : LoxObject)
    @fields[name.lexeme] = value
  end

  def to_s
    @klass.name + " instance"
  end
end
