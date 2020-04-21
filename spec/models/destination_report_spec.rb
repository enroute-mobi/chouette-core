
RSpec.describe DestinationReport, type: :model do
  it { should belong_to :publication }
  it { should belong_to :destination }
  it { should validate_presence_of :publication }
  it { should validate_presence_of :destination }

  let(:destination){ create(:destination_report) }

  describe '#start!' do
    it 'should set the started_at value' do
      expect{ destination.start! }.to change{ destination.started_at }
    end
  end

  describe '#failed!' do
    it 'should set the ended_at value' do
      expect{ destination.failed! }.to change{ destination.ended_at }
    end

    it 'should set the status' do
      expect{ destination.failed! }.to change{ destination.status }.to 'failed'
    end
  end

  describe '#success!' do
    it 'should set the ended_at value' do
      expect{ destination.success! }.to change{ destination.ended_at }
    end

    it 'should set the status' do
      expect{ destination.success! }.to change{ destination.status }.to 'successful'
    end
  end
end
