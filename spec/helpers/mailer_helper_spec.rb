describe MailerHelper, type: :helper do

  describe "#mail_subject" do
    let(:i18n) { "mailers.#{action}.#{method}.subject" }
    let(:subject_prefix) { Chouette::Config.mailer.subject_prefix }
    let(:subject_mailer) { [subject_prefix, I18n.t(i18n, attributes)].join(' ') }

    subject { mail_subject(i18n: i18n, method: method, attributes: attributes) }

    context 'when mail_subject has no attributes' do
      let(:method) { 'finished' }
      let(:action) { 'import_mailer' }
      let(:attributes) { {} }

      it "return subject mailer" do
        is_expected.to eq(subject_mailer)
      end
    end

    context 'when mail_subject has attributes' do
      let(:method) { 'invitation_from_user' }
      let(:action) { 'user_mailer' }
      let(:attributes) { {app_name: 'App name'} }

      it "return subject mailer with attributes" do
        is_expected.to eq(subject_mailer)
      end
    end
  end
end
