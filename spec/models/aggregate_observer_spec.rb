
RSpec.describe AggregateObserver, type: :observer do
  let(:user) { create :user, confirmed_at: Time.now }
  let(:workbench) { create :workbench }
  let(:ref1) { create :referential, workbench: workbench, organisation: workbench.organisation }
  let(:ref2) { create :referential, workbench: workbench, organisation: workbench.organisation }
  let(:notification_target) { nil }

  subject(:aggregate) do
    Aggregate.create(
      workgroup: referential.workgroup,
      referentials: [ref1, ref2],
      creator: user.name,
      user: user,
      notification_target: notification_target
    )
  end

  let(:mailer) { AggregateMailer }
  let(:observer) { AggregateObserver }

  before(:each) do
    workbench.update workgroup: aggregate.workgroup
    aggregate.workgroup.update owner: workbench.organisation
  end

  it_behaves_like 'a notifiable operation'
end
