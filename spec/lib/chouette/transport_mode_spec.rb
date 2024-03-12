# frozen_string_literal: true

RSpec.describe Chouette::TransportMode do
  subject(:transport_mode) { Chouette::TransportMode.new(mode, sub_mode) }

  let(:mode) { :dummy }
  let(:sub_mode) { nil }

  def transport_modes(definitions)
    definitions.map { |d| Chouette::TransportMode.from d }
  end

  describe '#mode_human_name' do
    subject { transport_mode.mode_human_name(locale: locale) }

    context 'when locale is :fr' do
      let(:locale) { :fr }

      context 'when mode is :rail' do
        let(:mode) { :rail }

        it { is_expected.to eq('Train') }
      end
    end

    context 'when locale is :en' do
      let(:locale) { :en }

      context 'when mode is :rail' do
        let(:mode) { :rail }

        it { is_expected.to eq('Rail') }
      end
    end
  end

  describe '#sub_mode_human_name' do
    subject { transport_mode.sub_mode_human_name(locale: locale) }

    context 'when sub_mode is not defined' do
      let(:sub_mode) { nil }
      let(:locale) { :fr }

      it { is_expected.to be_nil }
    end

    context 'when locale is :fr' do
      let(:locale) { :fr }

      context 'when mode is :rail' do
        let(:mode) { :rail }

        context 'when mode is :night_train' do
          let(:sub_mode) { :metro }

          it { is_expected.to eq('Train de nuit') }
        end
      end
    end

    context 'when locale is :en' do
      let(:locale) { :fr }

      context 'when mode is :rail' do
        let(:mode) { :rail }

        context 'when sub_mode is :night_train' do
          let(:sub_mode) { :night_train }

          it { is_expected.to eq('Night Train') }
        end
      end
    end
  end

  describe '#human_name' do
    subject { transport_mode.human_name }

    context 'when transport mode is invalid' do
      before { allow(transport_mode).to receive(:valid?).and_return(false) }
      it { is_expected.to be_nil }
    end

    context 'when transport mode is valid' do
      before { allow(transport_mode).to receive(:valid?).and_return(true) }

      context 'when mode human name is "Mode"' do
        before { allow(transport_mode).to receive(:mode_human_name).and_return('Mode') }

        context 'when sub_mode is not defined' do
          let(:sub_mode) { nil }

          it { is_expected.to eq('Mode') }
        end

        context 'when sub_mode human is "Submode"' do
          before { allow(transport_mode).to receive(:sub_mode_human_name).and_return('Submode') }
          let(:sub_mode) { :dummy }

          it { is_expected.to eq('Mode / Submode') }

          context 'when separator is "-"' do
            subject { transport_mode.human_name(separator: '-') }

            it { is_expected.to eq('Mode-Submode') }
          end
        end
      end
    end
  end

  describe '#code' do
    subject { transport_mode.code }

    context 'when mode is :rail' do
      let(:mode) { :rail }

      context "when sub mode isn't defined" do
        let(:sub_mode) { nil }

        it { is_expected.to eq('rail') }
      end

      context 'when sub mode is :night_train' do
        let(:sub_mode) { :night_train }

        it { is_expected.to eq('rail/night_train') }
      end
    end
  end

  describe '.from' do
    subject { Chouette :TransportMode.from definition }

    context 'when definition is nil' do
      it { is_expected.to be_nil }
    end

    context 'when definition is ""' do
      it { is_expected.to be_nil }
    end

    context 'when definition is "dummy"' do
      it { is_expected.to eq(Chouette: TransportMode(:dummy)) }
    end

    context 'when definition is "dummy/subdummy"' do
      it { is_expected.to eq(Chouette: TransportMode(:dummy, :subdummy)) }
    end
  end

  describe '#inspect' do
    subject { transport_mode.inspect }

    context 'when mode is :rail' do
      let(:mode) { :rail }

      context "when sub mode isn't defined" do
        let(:sub_mode) { nil }

        it { is_expected.to eq('#rail') }
      end

      context 'when sub mode is :metro' do
        let(:sub_mode) { :metro }

        it { is_expected.to eq('#rail/night_train') }
      end
    end
  end

  describe 'valid?' do
    subject { transport_mode.valid? }

    let(:transport_mode) { Chouette::TransportMode.from definition }

    %w[rail rail/night_train bus bus/special_needs_bus].each do |definition|
      context "with '#{definition}'" do
        let(:definition) { definition }

        it { is_expected.to be_truthy }
      end
    end

    %w[dummy dummy/wrong rail/metro rail/wrong].each do |definition|
      context "with '#{definition}'" do
        let(:definition) { definition }

        it { is_expected.to be_falsy }
      end
    end
  end

  describe '#sub_modes' do
    subject { transport_mode.sub_modes }

    context 'when mode is "dummy"' do
      let(:mode) { :dummy }

      it { is_expected.to be_empty }
    end

    context 'when mode is "metro"' do
      let(:mode) { :metro }

      it { is_expected.to eq(transport_modes(%w[metro/metro metro/tube metro/urban_railway])) }
    end

    context 'when mode is "snowAndIce"' do
      let(:mode) { :metro }

      let(:expected_transport_modes) do
        transport_modes(%w[
                          snow_and_ice/snow_mobile
                          snow_and_ice/snow_cat
                          snow_and_ice/snow_coach
                          snow_and_ice/terra_bus
                          snow_and_ice/wind_sled
                        ])
      end

      it { is_expected.to eq(expected_transport_modes) }
    end
  end

  describe '.modes' do
    subject { Chouette::TransportMode.modes }

    # Complete list from https://enroute.atlassian.net/wiki/spaces/CHOUET/pages/58163201/Transport+modes
    let(:expected_transport_modes) do
      transport_modes(%w[
                        metro
                        funicular
                        tram
                        rail
                        coach
                        bus
                        trolley_bus
                        water
                        telecabin
                        air
                        snow_and_ice
                        self_drive
                      ])
    end

    it { is_expected.to eq(expected_transport_modes) }
  end
end
