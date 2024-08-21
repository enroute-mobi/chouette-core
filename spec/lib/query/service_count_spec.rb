# frozen_string_literal: true

RSpec.describe Query::ServiceCount do
  subject(:query) { described_class.new(ServiceCount.all) }

  let(:context) do
    Chouette.create do
      workbench do
        company :company
        company :other_company

        network :network
        network :other_network

        line :line, company: :company, network: :network, transport_mode: 'bus'
        line :other_line, company: :other_company, network: :other_network, transport_mode: 'air'

        referential lines: %i[line other_line] do
          route line: :line do
            journey_pattern
          end
        end
      end
    end
  end

  let(:company) { context.company(:company) }
  let(:other_company) { context.company(:other_company) }
  let(:network) { context.network(:network) }
  let(:other_network) { context.network(:other_network) }
  let(:line) { context.line(:line) }
  let(:other_line) { context.line(:other_line) }
  let(:route) { context.route }
  let(:journey_pattern) { context.journey_pattern }

  let(:date) { DateTime.parse('2024-08-22T09:26:00') }
  let(:service_count) do
    ServiceCount.create!(line: line, route: route, journey_pattern: journey_pattern, date: date)
  end

  before do
    referential.switch
    service_count
  end

  describe '#line_ids' do
    subject { query.line_ids(line_ids).scope }

    context 'when line has service counts' do
      let(:line_ids) { [line] }
      it { is_expected.to eq([service_count]) }
    end

    context 'when line has no service count' do
      let(:line_ids) { [other_line] }
      it { is_expected.to be_empty }
    end

    context 'when line is empty' do
      let(:line_ids) { [] }
      it { is_expected.to eq([service_count]) }
    end
  end

  describe '#company_ids' do
    subject { query.company_ids(company_ids).scope }

    context 'when company has service counts' do
      let(:company_ids) { [company] }
      it { is_expected.to eq([service_count]) }
    end

    context 'when company has no service count' do
      let(:company_ids) { [other_company] }
      it { is_expected.to be_empty }
    end

    context 'when company is empty' do
      let(:company_ids) { [] }
      it { is_expected.to eq([service_count]) }
    end
  end

  describe '#network_id' do
    subject { query.network_ids(network_ids).scope }

    context 'when network has service counts' do
      let(:network_ids) { [network] }
      it { is_expected.to eq([service_count]) }
    end

    context 'when network has no service count' do
      let(:network_ids) { [other_network] }
      it { is_expected.to be_empty }
    end

    context 'when network is empty' do
      let(:network_ids) { [] }
      it { is_expected.to eq([service_count]) }
    end
  end

  describe '#transport_modes' do
    subject { query.transport_modes(transport_modes).scope }

    context 'when transport mode has service counts' do
      let(:transport_modes) { Set.new(['bus']) }
      it { is_expected.to eq([service_count]) }
    end

    context 'when transport mode has no service count' do
      let(:transport_modes) { Set.new(['air']) }
      it { is_expected.to be_empty }
    end

    context 'when transport mode is empty' do
      let(:transport_modes) { Set.new }
      it { is_expected.to eq([service_count]) }
    end
  end

  describe '#in_period' do
    subject { query.in_period(period).scope }

    context 'when period includes service count' do
      let(:period) { Period.new(from: date - 1.day, to: date + 1.day) }
      it { is_expected.to eq([service_count]) }
    end

    context 'when period is before service count' do
      let(:period) { Period.new(from: date - 2.days, to: date - 1.day) }
      it { is_expected.to be_empty }

      context 'without max range' do
        let(:period) { Period.new(from: date - 2.days, to: nil) }
        it { is_expected.to eq([service_count]) }
      end
    end

    context 'when period is after service count' do
      let(:period) { Period.new(from: date + 1.day, to: date + 2.days) }
      it { is_expected.to be_empty }

      context 'without min range' do
        let(:period) { Period.new(from: nil, to: date + 2.days) }
        it { is_expected.to eq([service_count]) }
      end
    end
  end

  describe '#days_of_week' do
    subject { query.days_of_week(days_of_week).scope }

    context 'when search for all week days' do
      let(:days_of_week) { Cuckoo::DaysOfWeek.all }
      it { is_expected.to eq([service_count]) }
    end

    context 'when search for no week day' do
      let(:days_of_week) { Cuckoo::DaysOfWeek.none }
      it { is_expected.to be_empty }
    end

    context 'when search for exactly the correct week day' do
      let(:days_of_week) { Cuckoo::DaysOfWeek.new(thursday: true) }
      it { is_expected.to eq([service_count]) }
    end

    context 'when search another week day' do
      let(:days_of_week) { Cuckoo::DaysOfWeek.new(tuesday: true) }
      it { is_expected.to be_empty }
    end
  end
end
