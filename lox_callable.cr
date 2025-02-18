abstract class LoxCallable
  abstract def call(interpreter, arguments)
  abstract def arity
end
