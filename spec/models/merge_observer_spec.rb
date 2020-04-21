
RSpec.describe MergeObserver, type: :observer do
  let(:user) { create :user, confirmed_at: Time.now }
  let(:stop_area_referential){ create :stop_area_referential }
  let(:line_referential){ create :line_referential }
  let(:company){ create :company, line_referential: line_referential }
  let(:workbench){ create :workbench, line_referential: line_referential, stop_area_referential: stop_area_referential }
  let(:referential) { create :referential, workbench: workbench, organisation: workbench.organisation }
  let(:referential_metadata){ create(:referential_metadata, lines: line_referential.lines.limit(3), referential: referential) }
  let(:notification_target) { nil }

  subject(:merge) do
    Merge.create workbench: referential.workbench,
                 referentials: [referential, referential],
                 creator: user.name,
                 user: user,
                 notification_target: notification_target
  end

  let(:mailer) { MergeMailer }
  let(:observer) { MergeObserver }

  it_behaves_like 'a notifiable operation'
end
