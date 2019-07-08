# frozen_string_literal: true

module RPN
  # RPN::Expression is the main entrypoint for this library.
  #
  # It can be initialized from an existing RPN expression (as an array) or an
  # infix string:
  #
  #   Expression.new(['20', '10', '+']).calc
  #   # => 30
  #
  #   Expression.from_infix('20 + 10').calc
  #   # => 30
  #
  class Expression
    attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def self.from_infix(infix)
      new(InfixParser.new(infix).parse)
    end

    # Calculate the value of an RPN expression.
    #
    # There is a bit of DRY-potential here with #to_infix_tree, but this is the
    # critical part of this library. We want calculations to be quick so I
    # don't think it's worth trying to avoid the (minimal) repetition.
    #
    def calc
      stack = []

      @expression.each do |term|
        if func = FUNCTIONS[term]
          argc = stack.pop # BigDecimal
          args = stack.pop(argc) # array of BigDecimal
          if args.size != argc
            raise ArgumentError, 'not enough operands on the stack'
          end

          stack.push(func.proc.call(*args))
        elsif op = OPS[term]
          a, b = stack.pop(2)
          raise ArgumentError, 'not enough operands on the stack' if b.nil?

          stack.push(a.public_send(op.ruby_op, b))
        else
          stack.push(Util.term_to_number(term))
        end
      end

      stack.pop
    end

    # express the AST as a string
    def to_infix
      to_infix_tree.to_s
    end

    private

    # convert an RPN expression into an AST
    def to_infix_tree
      stack = []

      @expression.each do |term|
        n = if func = FUNCTIONS[term]
              argc = Util.term_to_number(stack.pop.value)
              args = stack.pop(argc)
              if args.size != argc
                raise ArgumentError, 'not enough operands on the stack'
              end

              InfixNode.new(term, args: args)
            elsif OPS.key?(term)
              a, b = stack.pop(2)
              raise ArgumentError, 'not enough operands on the stack' if b.nil?

              InfixNode.new(term, left: a, right: b)
            else
              # the result of this isn't used, we just verify the term is ok
              Util.term_to_number(term)

              InfixNode.new(term)
            end
        stack.push(n)
      end

      stack.pop
    end
  end
end
