# frozen_string_literal: true

RSpec.describe Export::Part do
  subject(:part) { self.class::Test.new operation }

  class self::Test < Export::Part # rubocop:disable Lint/ConstantDefinitionInBlock,Style/ClassAndModuleChildren
    class Decorator < Export::Decorator
    end
  end

  let(:operation) { double(code_provider: double('Code Provider')) }

  describe '#decorate' do
    subject { part.decorate(model, **attributes) }

    let(:model) { double }
    let(:attributes) { {} }

    it { is_expected.to be_instance_of(part.default_decorator_class) }

    context 'when with option is used (here, with a Export::Decorator)' do
      let(:attributes) { { with: Export::Decorator } }

      it { is_expected.to be_instance_of(Export::Decorator) }
    end

    it { is_expected.to have_attributes(code_provider: operation.code_provider) }
    it { is_expected.to have_attributes(decorator_builder: part) }
  end

  describe '#export' do
    subject { part.export }

    it { is_expected.to eq(operation) }
  end

  describe '#default_decorator_class' do
    subject { part.default_decorator_class }

    it { is_expected.to eq(self.class::Test::Decorator) }
  end

  describe '#decorator_attributes' do
    subject { part.decorator_attributes }

    it { is_expected.to be_empty }
  end
end
