# frozen_string_literal: true

RSpec.describe Query::Line do
  describe '#query' do
    let(:query) { Query::Line.new(Chouette::Line.all) }

    let(:context) do
      Chouette.create do
        line :selected, {
          name: "Line selected",
        }
        line :other, {
          name: "Other line",
          transport_mode: "tram",
        }
        line_provider :line_provider_selected
        network :network_selected
        company :company_selected
      end
    end

    let(:selected) { context.line :selected }
    let(:other) { context.line :other }

    let(:scope) { query.send(criteria_id, criteria_value).scope }
    let(:today) { Time.zone.today }

    subject { scope == [selected] }

    describe '#text' do
      let(:criteria_id) { 'text' }
      let(:criteria_value) { 'Line selected' }

      it { is_expected.to be_truthy }
    end

    describe '#network_id' do
      let(:network_selected) { context.network(:network_selected) }
      let(:criteria_id) { 'network_id' }
      let(:criteria_value) { network_selected.id }

      before { selected.update network: network_selected}

      it { is_expected.to be_truthy }
    end

    describe '#company_id' do
      let(:company_selected) { context.company(:company_selected) }
      let(:criteria_id) { 'company_id' }
      let(:criteria_value) { company_selected.id }

      before { selected.update company: company_selected}

      it { is_expected.to be_truthy }
    end

    describe '#line_provider_id' do
      let(:line_provider_selected) { context.line_provider(:line_provider_selected) }
      let(:criteria_id) { 'line_provider_id' }
      let(:criteria_value) { selected.line_provider.id }

      before { selected.update line_provider: line_provider_selected}

      it { is_expected.to be_truthy }
    end

    describe '#transport_mode' do
      let(:criteria_id) { 'transport_mode' }
      let(:criteria_value) { 'bus' }

      it { is_expected.to be_truthy }
    end

    describe '#line_status' do
      let(:criteria_id) { 'line_status' }

      context 'when value is deactivated' do
        before do
          selected.update deactivated: true
          other.update deactivated: false
        end

        let(:criteria_value) { 'deactivated' }

        it { is_expected.to be_truthy }
      end

      context 'when value is activated' do
        before do
          selected.update deactivated: false
          other.update deactivated: true
        end

        let(:criteria_value) { 'activated' }

        it { is_expected.to be_truthy }
      end
    end

    describe '#in_period' do
      let(:criteria_id) { 'in_period' }
      let(:criteria_value) { Period.new(from: today, to: (today + 1.day)) }

      before do
        selected.update active_from: today + 1, active_until: today + 2
        other.update active_from: today + 1, active_until: today + 2
      end

      xit { is_expected.to be_truthy }
    end
  end
end
