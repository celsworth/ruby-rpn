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
    'sin' => Function.new(->(a) { Math.sin(a) }),
    'max' => Function.new(->(*a) { a.max }),
    'min' => Function.new(->(*a) { a.min }),
    'mean' => Function.new(->(*a) { a.sum / a.size }),
    'median' => Function.new(lambda do |*a|
      a.sort!
      hl = (a.size / 2.0).ceil
      (a[hl - 1] + a[-hl]) / 2.0
    end),
    'mode' => Function.new(lambda do |*a|
      a.group_by { |i| i }.values.max_by(&:size).first
    end)
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
