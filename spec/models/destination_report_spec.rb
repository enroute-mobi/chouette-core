# frozen_string_literal: true

RSpec.describe DestinationReport, type: :model do
  it { should belong_to :publication }
  it { should belong_to :destination }
  it { should validate_presence_of :publication }
  it { should validate_presence_of :destination }

  subject(:destination) { create(:destination_report) }

  describe '#start!' do
    subject { destination.start! }

    it 'should set the started_at value' do
      expect { subject }.to(change { destination.started_at })
    end
  end

  describe '#failed!' do
    subject { destination.failed! }

    it 'should set the ended_at value' do
      expect { subject }.to(change { destination.ended_at })
    end

    it 'should set the status' do
      expect { subject }.to change { destination.status }.to 'failed'
    end

    it 'does not set message nor backtrace' do
      expect { subject }.to(not_change { destination.error_message }.and(not_change { destination.error_backtrace }))
    end

    context 'with message' do
      subject { destination.failed!(message: 'This is an error.') }

      it 'sets the message' do
        expect { subject }.to change { destination.error_message }.to 'This is an error.'
      end
    end

    context 'with backtrace' do
      subject { destination.failed!(backtrace: caller) }

      it 'sets the backtrace' do
        expect { subject }.to change { destination.error_backtrace }.to be_present
      end
    end
  end

  describe '#success!' do
    subject { destination.success! }

    it 'should set the ended_at value' do
      expect { subject }.to(change { destination.ended_at })
    end

    it 'should set the status' do
      expect { subject }.to change { destination.status }.to 'successful'
    end
  end
end
