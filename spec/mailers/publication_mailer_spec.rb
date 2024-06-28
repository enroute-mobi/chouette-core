RSpec.describe PublicationMailer, type: :mailer do
  include ActionDispatch::TestProcess

  let(:publication) {create :publication, :with_gtfs}
  let(:publication_api) { create :publication_api }
  let(:destination_mail) { create :destination_mail, publication_setup: publication.publication_setup, publication_api: publication_api }

  let(:email) { PublicationMailer.send('publish', publication, destination_mail) }

  it 'should deliver email to recepients' do
    expect(email).to bcc_to destination_mail.recipients
  end

  it 'should have correct from' do
    expect(email.from).to eq(['chouette@example.com'])
  end

  it 'should have the provided subject' do
    expect(email).to have_subject destination_mail.email_title
  end

  it 'should contain the provided text' do
    # With Rails 4.2.11 upgrade, email body contains \r\n. See #9423
    expect(email.body.raw_source.gsub("\r\n","\n")).to include destination_mail.email_text
  end

  describe 'link to api' do
    context 'when provided' do
      before do
        destination_mail.update link_to_api: publication_api.id
      end

      it 'should contain publication api link' do
        expect(email.body.raw_source.gsub("\r\n","\n")).to include publication_api.public_url
      end
    end

    context 'when not provided' do
      it "shouldn't contain publication api link" do
        expect(email.body.raw_source.gsub("\r\n","\n")).not_to include publication_api.public_url
      end
    end
  end

  describe 'attachments' do
    let(:file) { fixture_file_upload('google-sample-feed.zip') }
    let! (:export) {create :gtfs_export, file: file, publication: publication}

    context 'with correct parameters' do
      before do
        destination_mail.update attached_export_file: true
      end

      context 'with no attached filename specified' do
        it 'should correctly attach exported file' do
          expect(email.attachments.count).to eq 1
        end

        it 'should name the attached file from the orginal exported filename' do
          expect(email.attachments[0].filename).to eq file.original_filename
        end
      end

      context 'with attached filename specified' do
        before do
          destination_mail.update attached_export_filename: "test-exported-filename"
        end

        it 'should correctly attach exported file' do
          expect(email.attachments.count).to eq 1
        end

        it 'should name the attached file from destination filename field' do
          expect(email.attachments[0].filename).to eq destination_mail.attached_export_filename
        end
      end

      context 'with attached filename specified with date patterns (publication created at 20300201 1205)', timezone: :random do
        subject { email.attachments[0].filename }

        before do
          publication.created_at = Time.zone.parse('2030-02-01 12:05')
          destination_mail.update attached_export_filename: "test-%{date:%Y%m%d}T%{date:%H%M}.zip"
        end

        it { is_expected.to eq 'test-20300201T1205.zip' }
      end
    end

    context 'with wrong parameters' do
      context 'with export file option set to false' do
        it "shouldn't attach exported file" do
          expect(email.attachments.count).to eq 0
        end
      end
    end

  end
end
