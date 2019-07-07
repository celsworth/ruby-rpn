# frozen_string_literal: true

module RPN
  Function = Struct.new(:proc) do
    def args
      @args ||= self.proc.arity
    end
  end
end
