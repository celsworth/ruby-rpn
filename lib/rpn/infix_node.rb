# frozen_string_literal: true

module RPN
  class InfixNode
    attr_reader :value, :args

    def initialize(value, left: nil, right: nil, args: nil)
      @value = value
      @left = left
      @right = right
      @args = args
    end

    def leaf?
      @left.nil? && @right.nil?
    end

    def to_s
      if @args
        # functions, such as max(1, 3)
        display_node(self)
      else
        # other operators, like 1 + 3
        [display_node(@left), @value, display_node(@right)].join(' ')
      end
    end

    def display_node(child)
      if child.args
        # child is a function
        t = child.args.map { |a| display_node(a) }.join(', ')
        return "#{child.value}(#{t})"
      end

      return child.value if child.leaf?

      cv = OPS[child.value]
      v = OPS[value]
      if (cv && v && cv.precedence < v.precedence) || (@right && !@right.leaf?)
        # We err on the side of caution and add parens whenever we *might* need
        # them.
        #
        # This does mean we sometimes add them when sometimes they weren't
        # necessary.
        #
        # In 4 + (1 - 1) for example, they are needed.
        # In 4 + (1 + 1) they're not, but working that out here
        # is probably not possible.. ?
        #
        "(#{child})"
      else
        child.to_s
      end
    end

    def inspect
      str = "node[#{value}]"
      str += "<left=#{@left.inspect}, right=#{@right.inspect}>" unless leaf?
      str += "<args=#{@args.inspect}>" if @args
      str
    end
  end
end
