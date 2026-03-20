# frozen_string_literal: true

RSpec.describe Scope::Composer do
  subject(:scope) { described_class.new(default_stack, **stacks) }

  let(:scope_base) do
    Class.new(Scope::Base) do
      def initialize(base)
        super()
        @base = base
      end
      attr_reader :base

      %i[some_collection some_other_collection].each do |name|
        collection name do
          base
        end
      end
    end
  end
  let(:scope_mult) do
    Class.new(Scope::Base) do
      def initialize(mult)
        super()
        @mult = mult
      end
      attr_reader :mult

      %i[some_collection some_other_collection].each do |name|
        collection name do
          current_collection * mult
        end
      end
    end
  end
  let(:scope_mult_other) do
    Class.new(Scope::Base) do
      def initialize(mult)
        super()
        @mult = mult
      end
      attr_reader :mult

      collection :some_other_collection do
        current_collection * mult
      end
    end
  end
  let(:scope_some_from_other) do
    Class.new(Scope::Base) do
      collection :some_collection do
        global_scope.some_other_collection * current_collection * 5
      end
    end
  end

  let(:default_stack) { [scope_base.new(1), scope_mult.new(2), scope_mult.new(3)] }
  let(:stacks) { {} }

  it 'calls all scopes of the stack' do
    expect(scope.some_collection).to eq(6)
  end

  context 'when a scope of the stack does not scope a collection' do
    let(:default_stack) { [scope_base.new(1), scope_mult_other.new(2), scope_mult.new(3)] }

    it 'passes this scope for this collection' do
      expect(scope.some_collection).to eq(3)
    end

    it 'does not pass this scope for the other collection' do
      expect(scope.some_other_collection).to eq(6)
    end
  end

  context 'when the first scope of the stack does not chain to the other scopes' do
    let(:default_stack) { [scope_base.new(42)] }

    it 'returns directly the result of the first scope' do
      expect(scope.some_collection).to eq(42)
    end
  end

  context 'when a scope in the stack is defined from another collection' do
    let(:default_stack) { [scope_base.new(1), scope_mult_other.new(2), scope_mult.new(3), scope_some_from_other.new] }

    it 'computes the correct result' do
      expect(scope.some_collection).to eq(6 * 3 * 5)
    end
  end

  context 'with a different stack for a collection' do
    let(:stacks) { { some_collection: [scope_base.new(1), scope_mult.new(2)] } }

    it 'uses this stack for this collection' do
      expect(scope.some_collection).to eq(2)
    end

    it 'uses the default stack for the other collection' do
      expect(scope.some_other_collection).to eq(6)
    end
  end
end
