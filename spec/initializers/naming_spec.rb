# frozen_string_literal: true

RSpec.describe ActiveModel::Name do
  with_model :some_model do
    model do
      class << self
        def i18n_key
          :some_model
        end
      end
    end
  end

  let(:translations) do # rubocop:disable Metrics/BlockLength
    {
      fr: {
        activerecord: {
          models: {
            some_model: {
              zero: 'Modèle',
              one: 'Modèle',
              other: 'Modèles',
              the: {
                one: 'le Modèle',
                other: 'les Modèles'
              },
              of: {
                one: 'du Modèle',
                other: 'des Modèles'
              },
              to: {
                one: 'au Modèle',
                other: 'aux Modèles'
              }
            }
          }
        }
      }
    }
  end

  around { |example| I18n.with_locale(:fr, &example) }
  before { allow(I18n.backend).to receive(:translations).and_return(translations) }

  subject(:model_name) { SomeModel.model_name }

  describe '#human' do
    subject { model_name.human(options) }

    let(:options) { {} }

    context 'without options' do
      it { is_expected.to eq('Modèle') }
    end

    context 'with count: 0' do
      let(:options) { { count: 0 } }
      it { is_expected.to eq('Modèle') }
    end

    context 'with count: 1' do
      let(:options) { { count: 1 } }
      it { is_expected.to eq('Modèle') }
    end

    context 'with count: 2' do
      let(:options) { { count: 2 } }
      it { is_expected.to eq('Modèles') }
    end
  end

  describe '#the_human' do
    subject { model_name.the_human(options) }

    let(:options) { {} }

    context 'without options' do
      it { is_expected.to eq('le Modèle') }
    end

    context 'with count: 1' do
      let(:options) { { count: 1 } }
      it { is_expected.to eq('le Modèle') }
    end

    context 'with count: 2' do
      let(:options) { { count: 2 } }
      it { is_expected.to eq('les Modèles') }
    end
  end

  describe '#of_human' do
    subject { model_name.of_human(options) }

    let(:options) { {} }

    context 'without options' do
      it { is_expected.to eq('du Modèle') }
    end

    context 'with count: 1' do
      let(:options) { { count: 1 } }
      it { is_expected.to eq('du Modèle') }
    end

    context 'with count: 2' do
      let(:options) { { count: 2 } }
      it { is_expected.to eq('des Modèles') }
    end
  end

  describe '#to_human' do
    subject { model_name.to_human(options) }

    let(:options) { {} }

    context 'without options' do
      it { is_expected.to eq('au Modèle') }
    end

    context 'with count: 1' do
      let(:options) { { count: 1 } }
      it { is_expected.to eq('au Modèle') }
    end

    context 'with count: 2' do
      let(:options) { { count: 2 } }
      it { is_expected.to eq('aux Modèles') }
    end
  end

  describe '#human_plural' do
    subject { model_name.human_plural }

    it { is_expected.to eq('Modèles') }
  end
end
