# frozen_string_literal: true

RSpec.describe RPN::Expression do
  # This section parses an infix input and checks the resulting RPN expression.
  #
  # No actual maths is tested here.
  describe '#expression from infix string' do
    def expression(expression)
      described_class.from_infix(expression).expression
    end

    it 'supports all known operators' do
      expect(expression('1+2-3*4/5^6')).to eq %w(1 2 + 3 4 * 5 6 ^ / -)
    end

    it 'supports floats' do
      expect(expression('0.1 + 1')).to eq %w(0.1 1 +)
      expect(expression('0.01 + 1')).to eq %w(0.01 1 +)
      expect(expression('.01 + 1')).to eq %w(.01 1 +)
    end

    it 'supports variable tokens' do
      expect(expression('$foo + 1')).to eq %w($foo 1 +)
      expect(expression('$foo/1')).to eq %w($foo 1 /)
      expect(expression('($foo*2)/1')).to eq %w($foo 2 * 1 /)
    end

    it 'supports functions' do
      expect(expression('sqrt(())')).to eq %w(0 sqrt)
      expect(expression('sqrt(1)')).to eq %w(1 1 sqrt)
      expect(expression('sqrt(1+1)')).to eq %w(1 1 + 1 sqrt)
      expect(expression('sqrt(1+1) + sqrt(2+2)'))
        .to eq %w(1 1 + 1 sqrt 2 2 + 1 sqrt +)
      expect(expression('sqrt((1+1))')).to eq %w(1 1 + 1 sqrt)
      expect(expression('sqrt((2 + 3) * 4)')).to eq %w(2 3 + 4 * 1 sqrt)
      expect(expression('max(1,2)')).to eq %w(1 2 2 max)
      expect(expression('max(1, 2)')).to eq %w(1 2 2 max)
      expect(expression('max(1 + 1, 2)')).to eq %w(1 1 + 2 2 max)
      expect(expression('max((1 + 1), 2)')).to eq %w(1 1 + 2 2 max)
    end

    it 'supports scientific notation' do
      expect(expression('5e1 + 1')).to eq %w(5e1 1 +)
      expect(expression('5e-1 + 1')).to eq %w(5e-1 1 +)
      expect(expression('5.1E-1 + 1')).to eq %w(5.1E-1 1 +)
    end

    it 'supports parentheses' do
      expect(expression('(1+2)+(3+4)')).to eq %w(1 2 + 3 4 + +)
      expect(expression('(1+(2+3))')).to eq %w(1 2 3 + +)
      expect(expression('((1+2)+3)')).to eq %w(1 2 + 3 +)
    end
  end # #expression

  # Test some mathematical outputs from an RPN expression input
  describe '#calc via .new' do
    def calc(expression)
      described_class.new(expression).calc
    end

    it 'supports an array of strings' do
      expect(calc(%w(10 20 +))).to eq 30
    end

    it 'supports an array of ints' do
      expect(calc([10, 20, '+'])).to eq 30
    end

    it 'supports an array of floats' do
      expect(calc([0.5, 15.0, '*'])).to eq 7.5
    end

    it 'supports an array of exponents' do
      expect(calc(['5.1e-1', '1.5e1', '*'])).to eq 7.65
    end

    it 'supports an array of BigDecimals' do
      expect(calc([BigDecimal('0.5'), BigDecimal('15'), '*'])).to eq 7.5
    end
  end # #calc via .new

  describe '#to_infix and #calc via .from_infix' do
    def outputs(expression)
      k = described_class.from_infix(expression)
      { calc: k.calc, infix: k.to_infix }
    end

    it 'copes with addition' do
      expect(outputs('1 + 1')).to eq infix: '1 + 1', calc: 2
      expect(outputs('0.01 + 1.1')).to eq infix: '0.01 + 1.1', calc: 1.11
    end

    it 'supports subtraction' do
      expect(outputs('30 - 10')).to eq infix: '30 - 10', calc: 20
      expect(outputs('30.5 - 0.5')).to eq infix: '30.5 - 0.5', calc: 30
    end

    it 'supports multiplication' do
      expect(outputs('30 * 10')).to eq infix: '30 * 10', calc: 300
      expect(outputs('5.5 * 10.1')).to eq infix: '5.5 * 10.1', calc: 55.55
    end

    it 'supports division' do
      expect(outputs('30 / 10')).to eq infix: '30 / 10', calc: 3
      expect(outputs('30 / 1.5')).to eq infix: '30 / 1.5', calc: 20
    end

    it 'supports exponentation' do
      expect(outputs('2 ^ 5')).to eq infix: '2 ^ 5', calc: 32
      expect(outputs('1.5 ^ 5')).to eq infix: '1.5 ^ 5', calc: 7.59375
    end

    it 'supports modulo' do
      expect(outputs('6 % 3')).to eq infix: '6 % 3', calc: 0
      expect(outputs('6 % 4')).to eq infix: '6 % 4', calc: 2
    end

    it 'supports sqrt' do
      expect(outputs('sqrt(9)')).to eq infix: 'sqrt(9)', calc: 3
      expect(outputs('sqrt(5+4)')).to eq infix: 'sqrt(5 + 4)', calc: 3
      expect(outputs('sqrt(1+3.41)')).to eq infix: 'sqrt(1 + 3.41)', calc: 2.1
    end

    it 'supports max' do
      expect(outputs('max(1, 2)')).to eq infix: 'max(1, 2)', calc: 2
      expect(outputs('max(1+3, 2)')).to eq infix: 'max(1 + 3, 2)', calc: 4
    end

    it 'supports min' do
      expect(outputs('min(1, 2)')).to eq infix: 'min(1, 2)', calc: 1
      expect(outputs('min(1+3, 2)')).to eq infix: 'min(1 + 3, 2)', calc: 2
    end

    it 'supports sin' do
      expect(outputs('sin(180)')).to eq infix: 'sin(180)', calc: Math.sin(180)
    end

    it 'supports avg' do
      expect(outputs('avg(1, 2, 3)')).to eq infix: 'avg(1, 2, 3)', calc: 2
      expect(outputs('avg(1, 2, 3, 5)'))
        .to eq infix: 'avg(1, 2, 3, 5)', calc: 2.75
    end

    it 'supports no spacing' do
      expect(outputs('(1/1+2-0)*5^3'))
        .to eq infix: '(1 / 1 + 2 - 0) * (5 ^ 3)', calc: 375
    end

    it 'supports odd space padding' do
      expect(outputs(' 1+1  -5 ')).to eq infix: '1 + 1 - 5', calc: -3
      expect(outputs('  ( 1/ 1  +2 -  0   )*   5 ^   3'))
        .to eq infix: '(1 / 1 + 2 - 0) * (5 ^ 3)', calc: 375
    end

    it 'uses the correct precedence' do
      expect(outputs('2 + 3 * 4')).to eq infix: '2 + (3 * 4)', calc: 14
      expect(outputs('2 + 4 / 2')).to eq infix: '2 + (4 / 2)', calc: 4
      expect(outputs('2 + 2 ^ 3')).to eq infix: '2 + (2 ^ 3)', calc: 10
      expect(outputs('5 - 4 % 3')).to eq infix: '5 - (4 % 3)', calc: 4
    end

    it 'supports order of operations' do
      expect(outputs('(5 + 5) * 10')).to eq infix: '(5 + 5) * 10', calc: 100
      expect(outputs('5 + (5 * 10)')).to eq infix: '5 + (5 * 10)', calc: 55
      expect(outputs('4 - (1 + 1)')).to eq infix: '4 - (1 + 1)', calc: 2
      expect(outputs('4 + (1 - 1)')).to eq infix: '4 + (1 - 1)', calc: 4
    end

    it 'supports functions with operators in arguments' do
      expect(outputs('sqrt(1+3)')).to eq infix: 'sqrt(1 + 3)', calc: 2
      expect(outputs('sqrt(4+5) + sqrt(3+6)'))
        .to eq infix: 'sqrt(4 + 5) + sqrt(3 + 6)', calc: 6
      expect(outputs('(sqrt(4+5) + sqrt(3+6)) * 2'))
        .to eq infix: '(sqrt(4 + 5) + sqrt(3 + 6)) * 2', calc: 12
    end

    # not keen on some of these. the 0 - is a bit messy, and the parens here
    # aren't necessary either. See comments in InfixNode#display_child as well.
    it 'supports unary operators' do
      expect(outputs('4+-(1+1)')).to eq infix: '4 + (0 - (1 + 1))', calc: 2
      expect(outputs('4++1')).to eq infix: '4 + 1', calc: 5
      expect(outputs('4+-1')).to eq infix: '4 + (0 - 1)', calc: 3
      expect(outputs('4+--1')).to eq infix: '4 + (0 - (0 - 1))', calc: 5
      expect(outputs('4+(--1)')).to eq infix: '4 + (0 - (0 - 1))', calc: 5
      expect(outputs('4/-1')).to eq infix: '4 / (0 - 1)', calc: -4
      expect(outputs('-1*-4')).to eq infix: '0 - (1 * (0 - 4))', calc: 4
      expect(outputs('-1*(---4)'))
        .to eq infix: '0 - (1 * (0 - (0 - (0 - 4))))', calc: 4
    end

    it 'supports functions with operators in the arguments' do
      expect(outputs('sqrt(4+5)')).to eq infix: 'sqrt(4 + 5)', calc: 3
      expect(outputs('sqrt((4 + 5) * 4)'))
        .to eq infix: 'sqrt((4 + 5) * 4)', calc: 6
      expect(outputs('max(1+1, 5)')).to eq infix: 'max(1 + 1, 5)', calc: 5
      expect(outputs('max(max(1 + 1, 1e1), 5)'))
        .to eq infix: 'max(max(1 + 1, 1e1), 5)', calc: 10
    end

    it 'does not add pointless parentheses' do
      expect(outputs('4+1-1')).to eq infix: '4 + 1 - 1', calc: 4
      expect(outputs('4-1+1')).to eq infix: '4 - 1 + 1', calc: 4
    end

    # Parens are hard. It's better to add too many than not enough though; the
    # bad end of the scale is "4+(1-1)" comes back out as "4+1-1" which is
    # blatantly wrong. Instead we prefer to add too many, so sometimes they
    # won't be necessary but they won't affect the result. That's ok.
    it 'adds/keeps appropriate parentheses' do
      expect(outputs('4+(1-1)')).to eq infix: '4 + (1 - 1)', calc: 4
      expect(outputs('4-(1+1)')).to eq infix: '4 - (1 + 1)', calc: 2
      expect(outputs('4+(1+1)')).to eq infix: '4 + (1 + 1)', calc: 6
      expect(outputs('(2+3)*(4+5)'))
        .to eq infix: '(2 + 3) * (4 + 5)', calc: 45
      expect(outputs('1/(2*4)/(1*2)'))
        .to eq infix: '(1 / (2 * 4)) / (1 * 2)', calc: 0.0625
      expect(outputs('1/((2*4)/(1*2))'))
        .to eq infix: '1 / ((2 * 4) / (1 * 2))', calc: 0.25
    end

    it 'removes redundant parentheses' do
      expect(outputs('(1/2)*3')).to eq infix: '1 / 2 * 3', calc: 1.5
      expect(outputs('(1+2)-3')).to eq infix: '1 + 2 - 3', calc: 0
    end

    it 'raises ArgumentError with unbalanced parentheses' do
      expect { outputs('(1+3))') }.to raise_error(ArgumentError)
      expect { outputs('((1+3)') }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError with insufficient function arguments' do
      expect { outputs('sqrt()') }.to raise_error(ArgumentError)
      expect { outputs('max(1)') }.to raise_error(ArgumentError)
    end
  end
end
