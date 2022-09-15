# frozen_string_literal: true

RSpec.describe Delayed::Job do
  subject(:job) { Delayed::Job.new }

  describe '.max_workers_per_organisation' do
    subject { Delayed::Job.max_workers_per_organisation }
    it { is_expected.to eq(1) }
  end

  describe '.store_organisation' do
    before { job.payload_object = payload_object }

    context 'when the payload object provides 42 as organisation id' do
      let(:payload_object) { double organisation_id: 42 }
      it { expect { job.send :store_organisation }.to change(job, :organisation_id).to(42) }
    end

    context 'when the payload object doesn\'t provide an organisation id' do
      let(:payload_object) { double }
      it { expect { job.send :store_organisation }.to_not change(job, :organisation_id).from(nil) }
    end
  end

  describe 'when Job is created' do
    before { job.handler = double(perform: true) }

    it do
      expect(job).to receive(:store_organisation)
      job.save!
    end
  end

  describe '.locked' do
    subject { Delayed::Job.locked }
    let(:job) { Delayed::Job.create! job_attributes.merge(handler: double(perform: true)) }

    context 'when locked_at is defined' do
      let(:job_attributes) { { locked_at: Time.zone.now } }
      it { is_expected.to include(job) }
    end

    context 'when locked_at is not defined' do
      let(:job_attributes) { { locked_at: nil } }
      it { is_expected.to_not include(job) }
    end
  end

  describe 'out_of_bounds_organizations' do
    subject { Delayed::Job.out_of_bounds_organizations }

    context 'when no job is defined' do
      it { is_expected.to be_empty }
    end

    context 'when max_workers_per_organisation is 3' do
      before { allow(Delayed::Job).to receive(:max_workers_per_organisation).and_return(3) }

      let(:organisation_id) { 42 }

      def create_job_with_organisation(attributes = {})
        attributes.reverse_merge! locked_at: Time.zone.now,
                                  organisation_id: organisation_id,
                                  handler: double(perform: true)
        Delayed::Job.create! attributes
      end

      context 'when 2 locked jobs is defined with organisation_id 42' do
        before { 2.times { create_job_with_organisation } }
        it { is_expected.to_not include(organisation_id) }
      end

      context 'when 2 locked jobs and unlock job is defined with organisation_id 42' do
        before do
          create_job_with_organisation locked_at: nil
          2.times { create_job_with_organisation }
        end
        it { is_expected.to_not include(organisation_id) }
      end

      context 'when 3 locked jobs is defined with organisation_id 42' do
        before { 3.times { create_job_with_organisation } }
        it { is_expected.to include(organisation_id) }
      end

      context 'when 4 locked jobs is defined with organisation_id 42' do
        before { 3.times { create_job_with_organisation } }
        it { is_expected.to include(organisation_id) }
      end

      context 'when 4 locked jobs are defined without organisation' do
        before do
          4.times do
            Delayed::Job.create! locked_at: Time.zone.now, handler: double(perform: true)
          end
        end

        it { is_expected.to be_empty }
      end
    end
  end

  describe '.reserve' do
    subject { Delayed::Job.reserve(worker) }

    let(:worker) { double name: 'Test' }

    def create_job(attributes = {})
      attributes.reverse_merge! handler: double(perform: true)
      Delayed::Job.create! attributes
    end

    context 'when a single unlocked job exists' do
      let!(:job) { create_job }
      it { is_expected.to eq(job) }
    end

    context 'when a locked single job exists' do
      let!(:job) { create_job locked_at: Time.zone.now }
      it { is_expected.to be_nil }
    end

    context 'when a single job exists for a given organisation' do
      let!(:job) { create_job organisation_id: 42 }
      it { is_expected.to eq(job) }
    end

    context 'when a job is locked for a given organisation and a another is unlocked/waiting' do
      let!(:locked_job) { create_job organisation_id: 42, locked_at: Time.zone.now }
      let!(:unlocked_job) { create_job organisation_id: 42 }
      it { is_expected.to be_nil }
    end

    context 'when a job is locked for a given organisation and a another is unlocked/waiting without organisation' do
      let!(:locked_job) { create_job organisation_id: 42, locked_at: Time.zone.now }
      let!(:unlocked_job) { create_job organisation_id: nil }

      it { is_expected.to eq(unlocked_job) }
    end
  end
end
