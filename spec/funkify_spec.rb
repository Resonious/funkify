require 'spec_helper'

describe Funkify do
  describe "auto_curry method" do
    before do
      @c = Class.new do
        include Funkify

        def alpha(x) x end
        def beta(x) x end
        auto_curry :beta

        def epsilon(x) x end

        def gamma(x) x end
        def zeta(x) x end
        auto_curry :gamma, :zeta

        auto_curry

        def harry(x) x end
        def joseph(x) x end
      end.new
    end

    it 'does not autocurry unselected methods' do
      expect{ @c.alpha }.to raise_error ArgumentError
    end

    it 'curries one method, when specified' do
      expect(@c.beta.is_a?(Proc)).to eq true
    end

    it 'does not curry methods after auto_curry used to curry a single method' do
      expect{ @c.epsilon }.to raise_error ArgumentError
    end

    it 'curries multiple methods when auto_curry given multiple args' do
      expect(@c.gamma.is_a?(Proc)).to eq true
      expect(@c.zeta.is_a?(Proc)).to eq true
    end

    it 'curries all methods after a call to auto_curry with no args' do
      expect(@c.harry.is_a?(Proc)).to eq true
      expect(@c.joseph.is_a?(Proc)).to eq true
    end
  end

  describe "currying behaviour" do
    before do
      @c = Class.new do
        include Funkify

        auto_curry

        def add(x, y, z)
          x + y + z
        end
      end.new
    end

    it 'invokes methods normally when all parameters are provided' do
      expect(@c.add(1, 2, 3)).to eq 6
    end

    it 'returns a curried Proc when less than required args are given' do
      expect(@c.add.is_a?(Proc)).to eq true
      expect(@c.add(1).is_a?(Proc)).to eq true
      expect(@c.add(1, 2).is_a?(Proc)).to eq true
    end

    it 'allows curried procs to be completed when the full args are provided successively' do
      expect(@c.add(1).(2).(3)).to eq 6
      expect(@c.add(1).(2, 3)).to eq 6
      expect(@c.add(1, 2).(3)).to eq 6
    end

    it 'raises an exception when too many args passed to curried Proc'  do
      expect{ @c.add(1, 2).(3, 4) }.to raise_error ArgumentError
    end
  end

  describe "composition" do
    before do
      @c = Class.new do
        include Funkify

        auto_curry

        def add(x, y)
          x + y
        end

        def mult(x, y)
          x * y
        end

        def negate(x)
          -x
        end

        def plus_1(x)
          x + 1
        end
      end.new
    end

    describe "normal composition" do
      it 'returns a new Proc when composing methods' do
        expect((@c.negate * @c.plus_1).is_a?(Proc)).to eq true
      end

      it 'invokes composed methods in the correct order (right-to-left)' do
        expect((@c.negate * @c.plus_1).(5)).to eq -6
      end

      it 'can compose partially applied methods' do
        expect((@c.add(5) * @c.mult(2)).(5)).to eq 15
      end

      it 'can compose multiple methods' do
        expect((@c.negate * @c.add(5) * @c.mult(5)).(5)).to eq -30
      end
    end

    describe "reverse composition" do
      it 'returns a new Proc when composing methods' do
        expect((@c.negate | @c.plus_1).is_a?(Proc)).to eq true
      end

      it 'invokes reverse-composed methods in the correct order (left-to-right)' do
        expect((@c.negate | @c.plus_1).(5)).to eq -4
      end

      it 'can reverse-compose partially applied methods' do
        expect((@c.add(5) | @c.mult(2)).(5)).to eq 20
      end

      it 'can reverse-compose multiple methods' do
        expect((@c.negate | @c.add(5) | @c.mult(5)).(5)).to eq 0
      end
    end

    describe "pass method" do
      it 'passes values into a reverse-composition stream' do
        expect((@c.pass(5) >= @c.add(5) | @c.mult(5))).to eq 50
      end

      it 'passes values into a normal-composition stream' do
        expect((@c.pass(5) >= @c.add(5) * @c.mult(5))).to eq 30
      end
    end
  end
end
