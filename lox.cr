require "./scanner"
require "./parser"
require "./ast_printer"

class Lox
  @@had_error = false

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

    parser = Parser.new(tokens)
    expression = parser.parse

    return if @@had_error

    puts AstPrinter.new.print(expression) # need to test!!!!!!

    # tokens.each do |token|
    #   puts token.to_s
    # end
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

  def self.report(line, where, message)
    puts "[line: #{line}] Error: #{message}"
    @@had_error = true
  end
end

Lox.new.main(ARGV)
