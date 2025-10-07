# frozen_string_literal: true

RSpec.describe Cron::DestroyDeletedAtWorkgroupsJob do
  it { is_expected.to be_a_kind_of(Cron::DailyJob) }

  describe '#perform' do
    subject { described_class.new.perform }

    let(:context) do
      Chouette.create do
        organisation :organisation

        workgroup :workgroup1, owner: :organisation
        workgroup :to_destroy, owner: :organisation, deleted_at: Time.zone.now
        workgroup :workgroup2, owner: :organisation
      end
    end
    let(:organisation) { context.organisation(:organisation) }

    it 'destroys workgroup to destroy and keeps other workgroups intact' do
      expect { subject }.to(
        change { Workgroup.where(owner_id: organisation.id) }.from(
          match_array(%i[workgroup1 workgroup2 to_destroy].map { |w| context.workgroup(w) })
        ).to(
          match_array(%i[workgroup1 workgroup2].map { |w| context.workgroup(w) })
        )
      )
    end
  end
end
