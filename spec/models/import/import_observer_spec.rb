
RSpec.describe ImportObserver, type: :observer do
  let(:user) { create :user, confirmed_at: Time.now }
  subject(:workbench_import) { create(:workbench_import, creator: user.name, user: user, notification_target: notification_target) }
  let(:referential) { create :referential }
  let(:mailer) { ImportMailer }
  let(:observer) { ImportObserver }

  it_behaves_like 'a notifiable operation'
end
