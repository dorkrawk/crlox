class LoxRuntimeError < Exception
  getter token : Token
  getter message

  def initialize(@token : Token, @message : String)
    super(message)
    @token = token
  end
end
