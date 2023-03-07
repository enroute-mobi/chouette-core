describe MailerHelper, type: :helper do
  let(:i18n) { "mailers.import_mailer.#{method}.subject" }
  let(:method) { 'finished' }
  let(:subject_prefix) { Chouette::Config.mailer.subject_prefix }
  let(:subject_mailer) { [subject_prefix, I18n.t(i18n)].join(' ') }

  describe "#mail_subject" do
    subject {mail_subject(i18n: i18n, method: method, attributes: {})}
    it "return subject mailer" do
      is_expected.to eq(subject_mailer)
    end
    context 'when mail_subject have attibutes arguments' do
      subject {mail_subject(i18n: i18n, method: method, attributes: {app_name: 'toto'})}
      it "return subject mailer with attributes" do
        is_expected.to eq(subject_mailer)
      end
    end
  end



  # def mail_subject(i18n: nil, method: 'finished', attributes: {})
  #   i18n ||= "mailers.#{self.class.name.underscore}.#{method}.subject"
  #   [subject_prefix, translate(i18n, attributes)].compact.join(' ')
  # end


end
