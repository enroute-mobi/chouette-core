RSpec.describe Destination::Mail, type: :model do
  let(:publication_api) { create :publication_api }
  let(:publication_setup) { create :publication_setup }
  let(:destination) { build :destination_mail, publication_setup: publication_setup, publication_api: publication_api }

  context "create / update mail destination" do
    describe '#email' do
      it { is_expected.not_to allow_value(["wellformated@mail.net","wrongformatedmail.net"]).for(:recipients) }
      it { is_expected.to allow_value(["wellformated@mail.net"]).for(:recipients) }
    end

    describe '#attached_export_filename' do
      it { is_expected.not_to allow_value("file*name99.zip").for(:attached_export_filename) }
      it { is_expected.to allow_value("new-file-name666.zip").for(:attached_export_filename) }
      it { is_expected.to allow_value("file.xml").for(:attached_export_filename) }
      it { is_expected.to allow_value("file-%{date:%F}.zip").for(:attached_export_filename) }
      it { is_expected.to allow_value("ARRET_SITE_ID_SITE_NAME_T_%{date:%AAAA%mm%jj}.xml").for(:attached_export_filename) }
    end

    describe '#email_text' do
      it 'should strip HTML tags before saving record ' do
        destination.email_text = "<ol> <li>Lorem ipsum dolor sit amet, consectetuer adipiscing elit.</li> <li>Aliquam tincidunt mauris eu risus.</li> <li>Vestibulum auctor dapibus neque.</li> </ol>"
        #Triggers the before_save callback
        destination.save
        expect(destination.reload.email_text).to eq " Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aliquam tincidunt mauris eu risus. Vestibulum auctor dapibus neque. "
      end
    end
  end
end
