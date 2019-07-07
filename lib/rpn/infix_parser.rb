# frozen_string_literal: true

module RPN
  class InfixParser
    attr_reader :expression

    def initialize(expression)
      @expression = expression

      # initialise some booleans..

      # This is true when the next operator we encounter should be considered
      # to be a unary operator, rather than a binary one.
      #
      # This should be true when:
      #
      #   * you're at the very start of the expression (hence true here)
      #   * immediately after an opening parenthesis
      #   * immediately after any other operator
      #
      # At all other times, it is false.
      #
      @next_op_is_unary = true

      # This array is appended to for each opening parenthesis we encounter,
      # with the symbol :precedence or :function.
      #
      # This is then used when encountering closing parentheses to determine
      # whether we are closing a layer of precedence, or closing a function.
      #
      @parens = []

      # A boolean to remember whether we are immediately beyond a function or
      # not. This is used to determine whether the next parenthesis we
      # encounter is a precedence or function parenthesis.
      @after_function = false
    end

    def parse
      Util.split_infix(expression).each do |term|
        if FUNCTIONS.key?(term) then handle_function(term)
        elsif OPS.key?(term) then handle_operator(term)
        elsif term == ',' then handle_comma
        elsif term == '(' then handle_opening_parenthesis
        elsif term == ')' then handle_closing_parenthesis
        else handle_operand(term)
        end

        # this boolean marks when we are immediately after a function, so
        # in the next loop iteration we can determine if a ( is a function
        # parenthesis or a precedence one.
        @after_function = FUNCTIONS.key?(term)
      end

      rpn_expr.concat(op_stack.reverse!)
    end

    private

    # Called when we encounter a known function.
    #
    # These are simply pushed onto the stack, and handle_closing_parenthesis
    # will work out when to pop them back off again.
    #
    def handle_function(function)
      op_stack << function
    end

    # Called when we encounter a known operator
    def handle_operator(operator)
      if @next_op_is_unary
        if operator == '-'
          # unary + are discarded. unary - are translated to "0 - next_term"
          rpn_expr << 0
          op_stack << operator
        end
      else
        op2 = op_stack.last
        rpn_expr << op_stack.pop if OPS.key?(op2) && (OPS[operator] < OPS[op2])
        op_stack << operator
        @next_op_is_unary = true
      end
    end

    # Called when we encounter a ,
    #
    # These are ignored, but act like a closing parenthesis, so stacked
    # operators are pushed onto the result.
    #
    # This means expressions like "max(1 + 3, 5)" will work (the 1 + 3 is
    # pushed onto the stack when we see the comma)
    #
    def handle_comma
      rpn_expr << op_stack.pop until op_stack.empty? || op_stack.last == '('
    end

    # Called when we encounter a (
    #
    # This works out if the parenthesis is for a function or precedence, and
    # remembers that for handle_closing_parenthesis to use later.
    #
    def handle_opening_parenthesis
      op_stack << '('
      @parens << (@after_function ? :function : :precedence)
      @next_op_is_unary = true
    end

    # Called when we encounter a )
    #
    def handle_closing_parenthesis
      rpn_expr << op_stack.pop until op_stack.empty? || op_stack.last == '('
      raise ArgumentError, 'unbalanced parentheses' if op_stack.empty?

      op_stack.pop # lose the opening paren
      if @parens.pop == :function
        # this was a function closing parenthesis, so pop the stacked
        # function onto the rpn expression
        rpn_expr << op_stack.pop
      end
      @next_op_is_unary = false
    end

    # Called when we encounter any other term
    def handle_operand(operand)
      rpn_expr << operand
      @next_op_is_unary = false
    end

    # The resulting output RPN expression
    def rpn_expr
      @rpn_expr ||= []
    end

    # A Stack of operators that are yet to be pushed onto the output
    def op_stack
      @op_stack ||= []
    end
  end
end
