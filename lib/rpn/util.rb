# frozen_string_literal: true

module RPN
  module Util
    module_function

    # Given an infix string normalise whitespace between the tokens and return
    # an Array of those tokens.
    #
    # The normalisation is so String#split will work.
    #
    #   so: "20*(-4.1+5)^4")
    #   => "20 * ( - 4.1 + 5 ) ^ 4"
    #   => ['20', '*', '(', '-', '4.1', '+', ')', '^', '4']
    #
    def split_infix(expression)
      expression.gsub(TOKEN_SPLIT_RE) { |s| " #{s} " }.strip.split(/ +/)
    end

    def term_to_number(term)
      return term if term.is_a?(Numeric)

      BigDecimal(term)
    rescue ArgumentError
      raise ArgumentError, "cannot handle term: #{term}"
    end
  end
end
