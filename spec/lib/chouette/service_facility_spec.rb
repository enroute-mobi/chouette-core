# frozen_string_literal: true

RSpec.describe Chouette::ServiceFacility do
  subject(:service_facility) { described_class.new(category, sub_category) }

  let(:category) { :dummy }
  let(:sub_category) { nil }

  describe '#category_human_name' do
    subject { service_facility.category_human_name(locale: locale) }

    context 'when locale is :fr' do
      let(:locale) { :fr }

      context 'when category is :accessibility_info' do
        let(:category) { :accessibility_info }

        it { is_expected.to eq("Informations d'accessibilité") }
      end
    end

    context 'when locale is :en' do
      let(:locale) { :en }

      context 'when category is :accessibility_info' do
        let(:category) { :accessibility_info }

        it { is_expected.to eq('Accessibility information') }
      end
    end
  end

  describe '#sub_category_human_name' do
    subject { service_facility.sub_category_human_name(locale: locale) }

    context 'when sub_category is not defined' do
      let(:sub_category) { nil }
      let(:locale) { :fr }

      it { is_expected.to be_nil }
    end

    context 'when locale is :fr' do
      let(:locale) { :fr }

      context 'when category is :accessibility_info' do
        let(:category) { :accessibility_info }

        context 'when category is :audio_information' do
          let(:sub_category) { :audio_information }

          it { is_expected.to eq('Informations audio') }
        end
      end
    end

    context 'when locale is :en' do
      let(:locale) { :en }

      context 'when category is :accessibility_info' do
        let(:category) { :accessibility_info }

        context 'when sub_category is :audio_information' do
          let(:sub_category) { :audio_information }

          it { is_expected.to eq('Audio information') }
        end
      end
    end
  end

  describe '#human_name' do
    subject { service_facility.human_name }

    context 'when transport category is invalid' do
      before { allow(service_facility).to receive(:valid?).and_return(false) }
      it { is_expected.to be_nil }
    end

    context 'when transport category is valid' do
      before { allow(service_facility).to receive(:valid?).and_return(true) }

      context 'when category human name is "Category"' do
        before { allow(service_facility).to receive(:category_human_name).and_return('Category') }

        context 'when sub_category is not defined' do
          let(:sub_category) { nil }

          it { is_expected.to eq('Category') }
        end

        context 'when sub_category human is "Subcategory"' do
          before { allow(service_facility).to receive(:sub_category_human_name).and_return('Subcategory') }
          let(:sub_category) { :dummy }

          it { is_expected.to eq('Category - Subcategory') }

          context 'when separator is "-"' do
            subject { service_facility.human_name(separator: '-') }

            it { is_expected.to eq('Category-Subcategory') }
          end
        end
      end
    end
  end

  describe '#code' do
    subject { service_facility.code }

    context 'when category is :accessibility_info' do
      let(:category) { :accessibility_info }

      context "when sub category isn't defined" do
        let(:sub_category) { nil }

        it { is_expected.to eq('accessibility_info') }
      end

      context 'when sub category is :audio_information' do
        let(:sub_category) { :audio_information }

        it { is_expected.to eq('accessibility_info/audio_information') }
      end
    end
  end
end
