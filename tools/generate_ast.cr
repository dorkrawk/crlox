class GenerateAst
  def main(args)
    if args.size != 1
      puts "Usage: generate_ast <output directory>"
      Process.exit(64)
    end

    output_dir = args[0]

    define_ast(output_dir, "Expr", [
      "Assign   : Token - name, Expr - value",
      "Binary   : Expr - left, Token - operator, Expr - right",
      "Grouping : Expr - expression",
      "Literal  : Bool | Nil | Float64 | String - value",
      "Logical  : Expr - left, Token - operator, Expr - right",
      "Unary    : Token - operator, Expr - right",
      "Variable : Token - name",
    ])

    define_ast(output_dir, "Stmt", [
      "Block      : Array(Stmt | Nil) - statements",
      "Expression : Expr - expression",
      "If         : Expr - condition, Stmt - then_branch, Stmt | Nil - else_branch",
      "Print      : Expr - expression",
      "Var        : Token - name, Expr | Nil - initializer",
    ])
  end

  def define_ast(output_dir, base_name, types)
    File.open("#{output_dir}/#{base_name.downcase}.cr", "w") do |file|
      file.puts <<-EOF
      abstract class #{base_name}
        abstract def accept(visitor : #{base_name}Visitor)
      EOF
      types.each do |type|
        class_name = type.split(":")[0].strip
        fields = type.split(":")[1].strip
        file.puts define_type(file, base_name, class_name, fields)
      end
      file.puts "end" # closes abstract class
    end
  end

  def define_type(file, base_name, class_name, fields)
    type_def = <<-EOF

      class #{class_name} < #{base_name}
        #{fields.split(", ").map do |field|
            "getter :#{field.split(" - ")[1]}"
          end.join("\n    ")}

        def initialize(#{fields.split(", ").map { |field| "#{field.split(" - ")[1]} : #{field.split(" - ")[0]}" }.join(", ")})
          #{fields.split(", ").map do |field|
              "@#{field.split(" - ")[1]} = #{field.split(" - ")[1]}"
            end.join("\n      ")}
        end

        def accept(visitor)
          visitor.visit_#{class_name.downcase}_#{base_name.downcase}(self)
        end
      end
    EOF
    type_def
  end
end

GenerateAst.new.main(ARGV)
