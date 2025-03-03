# frozen_string_literal: true

RSpec.describe Export::Decorator do
  subject(:decorator) { self.class::Test.new model }

  class self::Test < Export::Decorator
  end

  let(:model) { double }

  describe '#model' do
    subject { decorator.model }

    it { is_expected.to eq(model) }
  end

  describe '#code_provider' do
    subject { decorator.code_provider }

    it { is_expected.to eq(Export::CodeProvider.null) }
  end

  describe '#model_code' do
    subject { decorator.model_code }

    let(:expected_code) { 'Code from CodeProvider' }

    it do
      expect(decorator.code_provider).to receive(:code).with(model).and_return(expected_code)
      is_expected.to eq(expected_code)
    end
  end

  describe '#decorate' do
    subject { decorator.decorate(other_model, **attributes) }

    let(:other_model) { double }
    let(:attributes) { {} }

    it { is_expected.to be_instance_of(self.class::Test) }

    context 'when with option is used (here, with a Export::Decorator)' do
      let(:attributes) { { with: Export::Decorator } }

      it { is_expected.to be_instance_of(Export::Decorator) }
    end

    it { is_expected.to have_attributes(code_provider: decorator.code_provider) }

    context 'when decorator_builder is defined' do
      before { decorator.decorator_builder = decorator_builder }

      let(:decorator_builder) { double }
      let(:other_decorator) { double('Decorator created by Decorator Builder') }

      it do
        expect(decorator_builder).to receive(:decorate).with(other_model, **attributes).and_return(other_decorator)
        is_expected.to eq(other_decorator)
      end
    end
  end
end
