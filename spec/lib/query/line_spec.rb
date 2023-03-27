# frozen_string_literal: true

RSpec.describe Query::Line do
  describe '#text' do
    let(:context) do
      Chouette.create do
        line :expected
        line
      end
    end

    let(:query) { Query::Line.new(all_lines) }

    let(:all_lines) { context.line_referential.lines }
    let(:line) { context.line(:expected) }

    subject { query.scope }

    context 'when given text is blank' do
      before { query.text('') }
      it 'ignores this criteria' do
        is_expected.to match_array(all_lines)
      end
    end

    context "when given text is 'dummy'" do
      before { query.text('dummy') }

      context "when a Line is named 'Dummy'" do
        before { line.update name: 'Dummy' }

        it { is_expected.to contain_exactly(line) }
      end

      context "when a Line is named 'Line Dummy Sample'" do
        before { line.update name: 'Line Dummy Sample' }

        it { is_expected.to contain_exactly(line) }
      end

      context "when a Line has registration number 'DUMMY'" do
        before { line.update registration_number: 'DUMMY' }

        it { is_expected.to contain_exactly(line) }
      end

      context "when a Line has registration number 'PREFIX_DUMMY_SUFFIX'" do
        before { line.update registration_number: 'PREFIX_DUMMY_SUFFIX' }

        it { is_expected.to contain_exactly(line) }
      end

      context "when a Line has objectid 'chouette::Line::dummy::LOC'" do
        before { line.update objectid: 'chouette::Line::dummy::LOC' }

        it { is_expected.to contain_exactly(line) }
      end

      context "when a Line has a number 'Dummy'" do
        before { line.update number: 'Dummy' }

        it { is_expected.to contain_exactly(line) }
      end

      context "when a Line has a number 'Line Dummy Number'" do
        before { line.update number: 'Line Dummy Number' }

        it { is_expected.to contain_exactly(line) }
      end
    end
  end

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

    describe '#statuses' do
      let(:criteria_id) { 'statuses' }

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
        other.update active_from: today + 3, active_until: today + 4
      end

      it { is_expected.to be_truthy }
    end
  end
end
