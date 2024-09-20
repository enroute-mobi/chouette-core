# frozen_string_literal: true

RSpec.describe ExportMailer, type: :mailer do
  let(:context) do
    Chouette.create { referential }
  end

  let(:recipient) { 'user@test.com' }
  let(:export) do
    Export::Gtfs.create!(name: "Test", creator: 'test',
                         referential: context.referential,
                         workgroup: context.workgroup,
                         workbench: context.workbench)
  end
  subject(:email) { ExportMailer.finished(export.id, recipient) }

  it 'should deliver email to given email' do
    is_expected.to have_attributes(to: [recipient])
  end

  it { is_expected.to have_attributes(from: ['chouette@example.com']) }


  describe "#body" do
    # With Rails 4.2.11 upgrade, email body contains \r\n. See #9423
    subject(:body) { email.body.raw_source.gsub("\r\n","\n") }

    let(:expected_content) do
      I18n.t("mailers.export_mailer.finished.body", export_name: export.name,
             status: I18n.t("mailers.statuses.#{export.status}"))
    end

    it { is_expected.to include(expected_content) }

    it 'includes a link to the export' do
      is_expected.to include(ERB::Util.html_escape_once(I18n.t('mailers.export_mailer.button')))
      is_expected.to include(Rails.application.routes.url_helpers.workbench_export_path(context.workbench, export))
    end

    context 'when workbench is hidden' do
      before do
        context.workbench.update!(hidden: true)
        context.referential.update!(archived_at: Time.zone.now, workbench: nil)
        export.update!(workbench: nil)
      end

      it 'does not include a link to the export' do
        is_expected.not_to include(ERB::Util.html_escape_once(I18n.t('mailers.export_mailer.button')))
        is_expected.not_to(
          include(Rails.application.routes.url_helpers.workbench_export_path(context.workbench, export))
        )
      end
    end
  end
end
