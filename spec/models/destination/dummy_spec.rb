RSpec.describe Destination::Dummy, type: :model do
  let(:result){ :successful }
  let(:publication){ create(:publication) }

  let(:destination) do
    base = build(:destination)
    destination = Destination::Dummy.new(base.attributes)
    destination.result = result
    destination.save
    destination
  end

  context '#transmit' do
    it 'should create a DestinationReport' do
      expect{ destination.transmit(publication) }.to change { DestinationReport.count }.by(1)
      report = destination.reports.last
      expect(report.started_at).to be_present
      expect(report.ended_at).to be_present
    end

    it 'should set the status accordingly' do
      destination.transmit(publication)
      report = destination.reports.last
      expect(report.status).to eq result
    end

    context 'with an result set to unexpected_failure' do
      let(:result){ :unexpected_failure }

      it 'should set the status accordingly' do
        destination.transmit(publication)
        report = destination.reports.last
        expect(report.status).to eq "failed"
        expect(report.error_backtrace).to be_present
      end
    end

    context 'with an result set to expected_failure' do
      let(:result){ :expected_failure }

      it 'should set the status accordingly' do
        destination.transmit(publication)
        report = destination.reports.last
        expect(report.status).to eq "failed"
      end
    end
  end
end
