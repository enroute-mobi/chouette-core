
RSpec.describe ExportObserver, type: :observer do
  let(:user) { create :user, confirmed_at: Time.now }
  let(:notification_target) { nil }
  let(:parent) { create(:workbench_import, creator: user.name) }
  let(:referential) { create :referential }
  subject(:export) { create(:gtfs_export, creator: user.name, notification_target: notification_target, user: user) }
  let(:mailer) { ExportMailer }
  let(:observer) { ExportObserver }

  it_behaves_like 'a notifiable operation'
end
