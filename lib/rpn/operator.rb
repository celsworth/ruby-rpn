# frozen_string_literal: true

module RPN
  Operator = Struct.new(:precedence, :ruby_op, :associativity) do
    def <(other)
      if associativity == :left
        precedence <= other.precedence
      else
        precedence < other.precedence
      end
    end
  end
end
