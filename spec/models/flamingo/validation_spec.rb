# frozen_string_literal: true

RSpec.describe Flamingo::Validation do
  subject(:flamingo_validation) do
    flamingo_validation_setup.validations.create!(workbench: context.workbench, operation: import, creator: 'test')
  end

  let(:context) do
    Chouette.create do
      workgroup do
        flamingo_validation_setup ruleset: 'some_ruleset',
                                  include_schema: false,
                                  schema_version: 'next',
                                  token: 'some_token'
        workbench
      end
    end
  end
  let(:flamingo_validation_setup) { context.flamingo_validation_setup }
  let(:file) { file_fixture('google-sample-feed.zip').open }
  let(:import) do
    context.workbench.imports.create!(type: 'Import::Workbench', name: 'Test', creator: 'test', file: file)
  end

  it { is_expected.to belong_to(:setup) }
  it { is_expected.to belong_to(:workbench) }
  it { is_expected.to belong_to(:operation) }

  describe '#flamingo_server' do
    subject { flamingo_validation.flamingo_server }

    it do
      expect(Secretary::Server).to receive(:create).with(token: 'some_token')
      subject
    end
  end

  describe '#perform' do
    subject { flamingo_validation.perform }

    let(:flamingo_server) { instance_double(Secretary::Server) }
    let(:validation_id) { '914f8279-900d-4f43-bf1a-75d6976d0000' }

    before { allow(Secretary::Server).to receive(:new).and_return(flamingo_server) }

    it 'calls flamingo server with correct arguments' do
      import.file.cache!
      expect(flamingo_server).to receive(:validate).with(
        import.file.path,
        ruleset: 'some_ruleset',
        include_schema: false,
        schema_version: 'next',
        schema_ignore: [],
        publish: true
      )
      subject
    end

    context 'on successful validation' do
      before do
        allow(flamingo_server).to receive(:validate).and_return(
          Secretary::Validation.new(id: validation_id, user_status: 'successful', report_url: 'https://some/path')
        )
      end

      it { expect { subject }.to change(flamingo_validation, :user_status).to('successful') }

      it { expect { subject }.to change(flamingo_validation, :validation_id).to(validation_id) }

      it { expect { subject }.not_to change(flamingo_validation, :error_uuid).from(be_blank) }

      it { expect { subject }.to change(flamingo_validation, :validation_report_url).to('https://some/path') }

      it 'keeps attributes on reload' do
        subject
        flamingo_validation.reload
        expect(flamingo_validation).to have_attributes(
          user_status: 'successful',
          validation_id: validation_id,
          validation_report_url: be_present
        )
      end
    end

    context 'on failed validation' do
      before do
        allow(flamingo_server).to receive(:validate).and_return(
          Secretary::Validation.new(id: validation_id, user_status: 'failed', report_url: 'https://some/path')
        )
      end

      it { expect { subject }.to change(flamingo_validation, :user_status).to('failed') }

      it { expect { subject }.to change(flamingo_validation, :validation_id).to(validation_id) }

      it { expect { subject }.not_to change(flamingo_validation, :error_uuid).from(be_blank) }

      it { expect { subject }.to change(flamingo_validation, :validation_report_url).to('https://some/path') }
    end

    context 'on warning validation' do
      before do
        allow(flamingo_server).to receive(:validate).and_return(
          Secretary::Validation.new(id: validation_id, user_status: 'warning', report_url: 'https://some/path')
        )
      end

      it { expect { subject }.to change(flamingo_validation, :user_status).to('warning') }

      it { expect { subject }.to change(flamingo_validation, :validation_id).to(validation_id) }

      it { expect { subject }.not_to change(flamingo_validation, :error_uuid).from(be_blank) }

      it { expect { subject }.to change(flamingo_validation, :validation_report_url).to('https://some/path') }
    end

    context 'on pending validation' do
      before do
        allow(flamingo_server).to receive(:validate).and_return(
          Secretary::Validation.new(id: validation_id, user_status: 'pending')
        )
      end

      it { expect { subject }.to change(flamingo_validation, :user_status).to('failed') }

      it { expect { subject }.to change(flamingo_validation, :validation_id).to(validation_id) }

      it { expect { subject }.not_to change(flamingo_validation, :error_uuid).from(be_blank) }

      it { expect { subject }.not_to change(flamingo_validation, :validation_report_url).from(be_blank) }
    end

    context 'on exception' do
      before do
        allow(flamingo_server).to receive(:validate).and_raise(Secretary::Error, 'Fail to create a Validation: error')
      end

      it { expect { subject }.to change(flamingo_validation, :user_status).to('failed') }

      it { expect { subject }.not_to change(flamingo_validation, :validation_id).from(nil) }

      it { expect { subject }.to change(flamingo_validation, :error_uuid).to(be_present) }

      it { expect { subject }.not_to change(flamingo_validation, :validation_report_url).from(nil) }
    end
  end
end
