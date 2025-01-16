require "./scanner"
require "./parser"
require "./ast_printer"
require "./interpreter"

class Lox
  @@interpreter = Interpreter.new
  @@had_error = false
  @@had_runtime_error = false

  def main(args)
    if args.size > 1
      puts "Usage: lox [script]"
      Process.exit(64)
    elsif args.size == 1
      run_file(args[0])
    else
      run_prompt
    end
  end

  def run_file(file)
    source = File.read(file)
    run(source)
    Process.exit(65) if @@had_error
    Process.exit(70) if @@had_runtime_error
  end

  def run_prompt
    loop do
      print "> "
      line = gets
      break if line.nil? || line == "exit"
      run(line)
      @@had_error = false
    end
  end

  def run(source)
    scanner = Scanner.new(source)
    tokens = scanner.scan_tokens

    # tokens.each do |token|
    #   puts token.to_s
    # end

    parser = Parser.new(tokens)
    statements = parser.parse

    return if @@had_error

    @@interpreter.interpret(statements)
  end

  def self.error(line, message)
    self.report(line, "", message)
  end

  def self.error(token : Token, message : String)
    if token.type == TokenType::EOF
      report(token.line, " at end", message)
    else
      report(token.line, " at '#{token.lexeme}'", message)
    end
  end

  def self.runtime_error(token : Token, message : String)
    report(token.line, " at '#{token.lexeme}'", message)
    @@had_runtime_error = true
  end

  def self.report(line, where, message)
    puts "[line: #{line}] Error: #{message}"
    @@had_error = true
  end
end

Lox.new.main(ARGV)
