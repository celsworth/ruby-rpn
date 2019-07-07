# frozen_string_literal: true

module RPN
  OPS = {
    '^' => Operator.new(4, :**, :right),
    '/' => Operator.new(3, :/, :left),
    '*' => Operator.new(3, :*, :left),
    '%' => Operator.new(3, :%, :left),
    '-' => Operator.new(2, :-, :left),
    '+' => Operator.new(2, :+, :left)
  }.freeze

  FUNCTIONS = {
    'sqrt' => Function.new(->(a) { a.sqrt(5) }), # precision of at least 5dp
    'max' => Function.new(->(a, b) { [a, b].max }),
    'min' => Function.new(->(a, b) { [a, b].min }),
    'sin' => Function.new(->(a) { Math.sin(a) })
  }.freeze

  # Match tokens for splitting out from an infix string.
  #
  # This matches:
  #
  #   * numerics (ints, floats, scientific notation)
  #   * variables, which are $foo, where foo can be a-z
  #   * opening and closing parens
  #   * any operator key from the OPS hash above
  #
  # Functions we kind of get for free here, sqrt(x) ends up being treated like
  # any other parens and becomes sqrt ( x )
  #
  TOKEN_SPLIT_RE = Regexp.union(/(\d*\.?\d+([eE][+-]?\d+)?)/,
                                /($[a-z]+)/,
                                /\(/, /\)/,
                                *OPS.keys)
end
