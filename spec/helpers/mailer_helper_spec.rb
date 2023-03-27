# frozen_string_literal: true

describe MailerHelper, type: :helper do
  before { allow(helper.class).to receive(:name).and_return('test') }

  describe '#subject_prefix' do
    subject { helper.subject_prefix }

    context 'when Chouette::Config.mailer.subject_prefix is "dummy"' do
      before { allow(Chouette::Config.mailer).to receive(:subject_prefix).and_return('dummy') }
      it { is_expected.to eq('dummy') }
    end
  end

  describe '#mail_subject' do
    context 'when i18n key is given' do
      subject { helper.mail_subject(i18n: '18n key') }

      let(:i18n_subject) { 'i18n translation of given key' }
      before { allow(helper).to receive(:translate).with('18n key', {}).and_return(i18n_subject) }

      it { is_expected.to eq(i18n_subject) }
    end

    context 'when no i18n key is given' do
      context 'when a method is given' do
        subject { helper.mail_subject(method: '<method>') }

        let(:i18n_subject) { "i18n translation of 'mailers.<class>.<method>.subject'" }
        before do
          allow(helper).to receive(:translate).with('mailers.test.<method>.subject', {}).and_return(i18n_subject)
        end

        it { is_expected.to eq(i18n_subject) }
      end

      context 'when no method is given' do
        subject { helper.mail_subject }

        let(:i18n_subject) { "i18n translation of 'mailers.<class>.finished.subject'" }
        before do
          allow(helper).to receive(:translate).with('mailers.test.finished.subject', {}).and_return(i18n_subject)
        end

        it { is_expected.to eq(i18n_subject) }
      end
    end

    context 'when i18n attributes are given' do
      subject { helper.mail_subject(attributes: attributes) }

      let(:attributes) { { dummy: true } }

      let(:i18n_subject) { "i18n translation with attributes" }
      before do
        allow(helper).to receive(:translate).with(a_value, attributes).and_return(i18n_subject)
      end

      it { is_expected.to eq(i18n_subject) }
    end

    context 'when subject_prefix is "prefix"' do
      subject { helper.mail_subject }

      before { allow(helper).to receive(:subject_prefix).and_return('prefix') }

      it { is_expected.to start_with(helper.subject_prefix) }
    end
  end
end
