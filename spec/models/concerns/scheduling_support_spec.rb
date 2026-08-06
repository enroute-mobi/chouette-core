# frozen_string_literal: true

RSpec.describe SchedulingSupport do
  subject(:scheduling_record) { SchedulingModel.create! }

  with_model :scheduling_model do
    table do |t|
      t.time :time_attribute, null: false, default: '2000-01-01 00:00:00'
      t.bit :days_attribute, null: false, limit: 7, default: '1111111'
      t.references :scheduled_job, foreign_key: { to_table: :delayed_jobs }
    end

    model do
      include SchedulingSupport

      schedule_by :time_attribute, :days_attribute

      class self::ScheduledJob < SchedulingSupport::ScheduledJob # rubocop:disable Lint/ConstantDefinitionInBlock,Style/ClassAndModuleChildren
        def perform; end
      end
    end
  end

  it { is_expected.not_to allow_value(Cuckoo::DaysOfWeek.none).for(:days_attribute) }

  describe '#schedule_time' do
    subject { scheduling_record.schedule_time }

    it 'aliases #time_attribute' do
      scheduling_record.time_attribute = TimeOfDay.new(7, 55)
      is_expected.to eq(TimeOfDay.new(7, 55))
    end
  end

  describe '#schedule_days' do
    subject { scheduling_record.schedule_days }

    it 'aliases #days_attribute' do
      scheduling_record.days_attribute = Cuckoo::DaysOfWeek.new(monday: true, tuesday: true)
      is_expected.to eq(Cuckoo::DaysOfWeek.new(monday: true, tuesday: true))
    end
  end

  describe '#scheduled_job' do
    subject(:scheduled_job) { scheduling_record.scheduled_job }

    it do
      expect(scheduled_job).to have_attributes(
        handler: match(/SchedulingModel::ScheduledJob/),
        cron: '0 0 * * *'
      )
    end

    context '#next_schedule' do
      subject { scheduling_record.next_schedule }

      it { is_expected.to be_present }
    end

    context '#reschedule' do
      subject { scheduling_record.reschedule }

      it { expect { subject }.not_to(change { scheduled_job.reload.attributes }) }

      context 'when scheduled job has wrong attributes' do
        before { scheduled_job.update(cron: '1 2 3 4 5') }

        it do
          expect { subject }.to(
            change { scheduled_job.reload.cron }.and(change { scheduled_job.reload.run_at })
          )
        end
      end
    end

    context 'when #time_attribute changes' do
      subject { scheduling_record.update(time_attribute: TimeOfDay.new(12, 20)) }

      it do
        expect { subject }.to(
          change { scheduled_job.reload.cron }.to('20 12 * * *').and(change { scheduled_job.reload.run_at })
        )
      end
    end

    context 'when #days_attribute changes' do
      subject { scheduling_record.update(days_attribute: Cuckoo::DaysOfWeek.new(monday: true, tuesday: true)) }

      it { expect { subject }.to change { scheduled_job.reload.cron }.to('0 0 * * 1,2') }
    end

    context 'when scheduled record is destroyed' do
      before { scheduling_record.destroy }

      it { expect { scheduled_job.reload }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'if scheduled job is destroyed' do
      before do
        job = scheduled_job
        scheduling_record.update_column(:scheduled_job_id, nil)
        job.destroy
      end

      context '#next_schedule' do
        subject { scheduling_record.next_schedule }

        it { is_expected.to eq(nil) }
      end

      context '#reschedule' do
        subject { scheduling_record.reschedule }

        it do
          expect { subject }.to change { scheduling_record.scheduled_job }.from(nil).to(
            have_attributes(handler: match(/SchedulingModel::ScheduledJob/))
          )
        end
      end

      context 'when #time_attribute changes' do
        subject { scheduling_record.update(time_attribute: TimeOfDay.new(12, 20)) }

        it do
          expect { subject }.to change { scheduling_record.scheduled_job }.from(nil).to(
            have_attributes(
              handler: match(/SchedulingModel::ScheduledJob/),
              cron: '20 12 * * *'
            )
          )
        end
      end

      context 'when #days_attribute changes' do
        subject { scheduling_record.update(days_attribute: Cuckoo::DaysOfWeek.new(monday: true, tuesday: true)) }

        it do
          expect { subject }.to change { scheduling_record.scheduled_job }.from(nil).to(
            have_attributes(
              handler: match(/SchedulingModel::ScheduledJob/),
              cron: '0 0 * * 1,2'
            )
          )
        end
      end
    end
  end

  context 'when a scheduling can be disabled' do
    subject(:scheduling_record) { SchedulableModel.create!(scheduling: scheduling) }

    with_model :schedulable_model do
      table do |t|
        t.boolean :scheduling, null: false, default: false
        t.time :time_attribute, null: false, default: '2000-01-01 00:00:00'
        t.bit :days_attribute, null: false, limit: 7, default: '1111111'
        t.references :scheduled_job, foreign_key: { to_table: :delayed_jobs }
      end

      model do
        include SchedulingSupport

        schedule_by :time_attribute, :days_attribute

        class self::ScheduledJob < SchedulingSupport::ScheduledJob # rubocop:disable Lint/ConstantDefinitionInBlock,Style/ClassAndModuleChildren
          def perform; end
        end

        protected

        def scheduling_enabled?
          scheduling?
        end

        def saved_change_to_scheduling_enabled?
          saved_change_to_scheduling?
        end
      end
    end

    describe '#scheduled_job' do
      subject(:scheduled_job) { scheduling_record.scheduled_job }

      context 'when #scheduling is true' do
        let(:scheduling) { true }

        it 'exists' do
          expect(subject).to be_present
        end
      end

      context 'when #scheduling is false' do
        let(:scheduling) { false }

        it 'does not exist' do
          expect(subject).to be_nil
        end
      end

      context '#reschedule' do
        subject { scheduling_record.reschedule }

        let(:scheduling) { true }

        it { expect { subject }.not_to(change { scheduled_job.reload.attributes }) }

        context 'when scheduled job has wrong attributes' do
          before { scheduled_job.update(cron: '1 2 3 4 5') }

          it do
            expect { subject }.to(
              change { scheduled_job.reload.cron }.and(change { scheduled_job.reload.run_at })
            )
          end
        end

        context 'when scheduled job should not exist' do
          before { scheduling_record.update_column(:scheduling, false) }

          it 'destroys scheduled job' do
            expect { subject }.to(
              change { scheduling_record.reload.scheduled_job_id }.from(be_present).to(be_nil).and(
                change { scheduled_job&.reload rescue nil }.from(be_present).to(be_nil) # rubocop:disable Style/RescueModifier
              )
            )
          end
        end
      end

      context 'when #scheduling changes' do
        context 'to true' do
          subject { scheduling_record.update(scheduling: true) }

          let(:scheduling) { false }

          it 'creates scheduled job' do
            expect { subject }.to(change { scheduling_record.reload.scheduled_job_id }.from(be_nil).to(be_present))
          end
        end

        context 'to false' do
          subject { scheduling_record.update(scheduling: false) }

          let(:scheduling) { true }

          it 'destroys scheduled job' do
            expect { subject }.to(
              change { scheduling_record.reload.scheduled_job_id }.from(be_present).to(be_nil).and(
                change { scheduled_job&.reload rescue nil }.from(be_present).to(be_nil) # rubocop:disable Style/RescueModifier
              )
            )
          end
        end
      end

      context 'when #time_attribute changes' do
        subject { scheduling_record.update(time_attribute: TimeOfDay.new('12', '20', time_zone: Time.zone)) }

        context 'when #scheduling is true' do
          let(:scheduling) { true }

          it do
            expect { subject }.to(
              change { scheduled_job.reload.cron }.to('20 12 * * *').and(change { scheduled_job.reload.run_at })
            )
          end
        end

        context 'when #scheduling is false' do
          let(:scheduling) { false }

          it 'does nothing' do
            expect { subject }.not_to change { scheduling_record.reload.scheduled_job_id }.from(be_nil)
          end
        end
      end

      context 'when #days_attribute changes' do
        subject { scheduling_record.update(days_attribute: Cuckoo::DaysOfWeek.new(monday: true, tuesday: true)) }

        context 'when #scheduling is true' do
          let(:scheduling) { true }

          it do
            expect { subject }.to(
              change { scheduled_job.reload.cron }.to('0 0 * * 1,2')
            )
          end
        end

        context 'when #scheduling is not false' do
          let(:scheduling) { false }

          it 'does nothing' do
            expect { subject }.not_to change { scheduling_record.reload.scheduled_job_id }.from(be_nil)
          end
        end
      end

      context 'if scheduled job is destroyed' do
        before do
          job = scheduled_job
          scheduling_record.update_column(:scheduled_job_id, nil)
          job.destroy
        end

        let(:scheduling) { true }

        context '#reschedule' do
          subject { scheduling_record.reschedule }

          context 'when #scheduling is true' do
            it 'creates scheduled job' do
              expect { subject }.to(change { scheduling_record.reload.scheduled_job_id }.from(be_nil).to(be_present))
            end
          end

          context 'when #scheduling is false' do
            before { scheduling_record.update_column(:scheduling, false) }

            it 'does nothing' do
              expect { subject }.not_to change { scheduling_record.reload.scheduled_job_id }.from(be_nil)
            end
          end
        end

        context 'when #scheduling changes' do
          context 'to true' do
            subject { scheduling_record.update(scheduling: true) }

            before { scheduling_record.update_column(:scheduling, false) }

            it 'creates scheduled job' do
              expect { subject }.to(change { scheduling_record.reload.scheduled_job_id }.from(be_nil).to(be_present))
            end
          end

          context 'to false' do
            subject { scheduling_record.update(scheduling: false) }

            it 'does nothing' do
              expect { subject }.not_to change { scheduling_record.reload.scheduled_job_id }.from(be_nil)
            end
          end
        end

        context 'when #time_attribute changes' do
          subject { scheduling_record.update(time_attribute: TimeOfDay.new('12', '20')) }

          context 'when #scheduling is true' do
            it 'creates scheduled job' do
              expect { subject }.to(change { scheduling_record.reload.scheduled_job_id }.from(be_nil).to(be_present))
            end
          end

          context 'when #scheduling is false' do
            before { scheduling_record.update_column(:scheduling, false) }

            it 'does nothing' do
              expect { subject }.not_to change { scheduling_record.reload.scheduled_job_id }.from(be_nil)
            end
          end
        end

        context 'when #days_attribute changes' do
          subject { scheduling_record.update(days_attribute: Cuckoo::DaysOfWeek.new(monday: true, tuesday: true)) }

          context 'when #scheduling is false' do
            it 'creates scheduled job' do
              expect { subject }.to(change { scheduling_record.reload.scheduled_job_id }.from(be_nil).to(be_present))
            end
          end

          context 'when #scheduling is false' do
            before { scheduling_record.update_column(:scheduling, false) }

            it 'does nothing' do
              expect { subject }.not_to change { scheduling_record.reload.scheduled_job_id }.from(be_nil)
            end
          end
        end
      end
    end
  end
end
