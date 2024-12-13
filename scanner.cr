require "./token"
require "./token_type"
require "./lox"

class Scanner
  @source : String

  def initialize(@source)
    @start = 0
    @current = 0
    @line = 1
    @tokens = [] of Token
  end

  def scan_tokens
    while !is_at_end?
      @start = @current
      scan_token
    end

    @tokens << Token.new(TokenType::EOF, "", nil, @line)
    @tokens
  end

  def scan_token
    c = advance

    case c
    when '('
      add_token(TokenType::LEFT_PAREN)
    when ')'
      add_token(TokenType::RIGHT_PAREN)
    when '{'
      add_token(TokenType::LEFT_BRACE)
    when '}'
      add_token(TokenType::RIGHT_BRACE)
    when ','
      add_token(TokenType::COMMA)
    when '.'
      add_token(TokenType::DOT)
    when '-'
      add_token(TokenType::MINUS)
    when '+'
      add_token(TokenType::PLUS)
    when ';'
      add_token(TokenType::SEMICOLON)
    when '*'
      add_token(TokenType::STAR)
    when '!'
      add_token(match('=') ? TokenType::BANG_EQUAL : TokenType::BANG)
    when '='
      add_token(match('=') ? TokenType::EQUAL_EQUAL : TokenType::EQUAL)
    when '<'
      add_token(match('=') ? TokenType::LESS_EQUAL : TokenType::LESS)
    when '>'
      add_token(match('=') ? TokenType::GREATER_EQUAL : TokenType::GREATER)
    when '/'
      if match('/')
        while peek != '\n' && !is_at_end?
          advance
        end
      else
        add_token(TokenType::SLASH)
      end
    when ' ', '\r', '\t'
      # Ignore whitespace.
    when '\n'
      @line += 1
    when '"'
      string
    else
      if is_digit?(c)
        number
      elsif is_alpha?(c)
        identifier
      else
        Lox.error(@line, "Unexpected character.")
      end
    end
  end

  def match(expected)
    # return false if is_at_end?
    # return false if @source[@current] != expected

    # @current++
    
    return false if peek != expected
    advance
    true
  end

  def peek
    return '\0' if is_at_end?
    @source[@current]
  end

  def peek_next
    return '\0' if @current + 1 >= @source.size
    @source[@current + 1]
  end

  def advance
    c = @source[@current]
    @current += 1
    c
  end

  def string
    while peek != '"' && !is_at_end?
      @line += 1 if peek == '\n' # supporting multi-line strings
      advance
    end

    if is_at_end?
      Lox.error(@line, "Unterminated string.")
      return
    end

    # The closing " (at this point we should be seeing a '"').
    advance

    # Trim the surrounding quotes for the token value.
    value = @source[@start + 1...@current - 1]
    add_token(TokenType::STRING, value)
  end

  def number
    while is_digit?(peek)
      advance
    end

    if peek == '.' && is_digit?(peek_next)
      # Consume the "."
      advance

      while is_digit?(peek)
        advance
      end
    end

    add_token(TokenType::NUMBER, @source[@start...@current].to_f)
  end 

  def identifier
    while /[a-zA-Z0-9_]/.match(peek.to_s)
      advance
    end
    text = @source[@start...@current]
    if Token::KEYWORDS.has_key?(text)
      type = Token::KEYWORDS[text]
    else
      type = TokenType::IDENTIFIER
    end 

    add_token(type)
  end

  def add_token(type, literal = nil)
    text = @source[@start...@current]
    new_token = Token.new(type, text, literal, @line)
    # puts new_token.to_s
    @tokens << new_token
  end

  def is_digit?(c)
    c >= '0' && c <= '9'
  end

  def is_alpha?(c)
    (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
  end

  def is_at_end?
    @current >= @source.size
  end
end
