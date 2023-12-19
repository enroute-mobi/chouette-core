# frozen_string_literal: true

load(Rails.root.join('db/migrate/20231218172935_migrate_attachment_custom_fields_to_document_memberships.rb'))

RSpec.describe MigrateAttachmentCustomFieldsToDocumentMemberships, type: :migration do
  subject { Apartment::Tenant.switch('public') { described_class.new.up } }

  context 'Chouette::Company' do
    let(:context) do
      Chouette.create do
        workbench organisation: Organisation.find_by(code: 'first') do
          company :c1, name: 'Company one', short_name: 'C1'

          referential
        end
      end
    end

    let(:workgroup) { context.workgroup }
    let(:workbench) { context.workbench }
    let(:referential) { context.referential }

    let(:custom_field_group) { workgroup.custom_field_groups.create!(name: 'Documents', resource_type: 'Company') }
    let(:custom_field) do
      workgroup.custom_fields.create!(
        code: 'plop',
        name: 'Attachments',
        resource_type: 'Company',
        field_type: 'attachment',
        custom_field_group: custom_field_group,
        options: { 'section' => 'identification' }
      )
    end

    let(:company) do
      company = context.company(:c1)
      company = company.class.find(company.id)
      company.update(custom_field_values: { plop: open_fixture('sample_png.png') })
      company
    end

    before do
      custom_field
      company
      subject
    end

    it 'creates a new document with the same content as the custom field' do
      document = company.documents.first
      expect(document).to have_attributes(
        name: 'Attachments Company one',
        document_provider_id: workbench.default_document_provider.id
      )
      expect(File.read(document.file.path)).to eq(read_fixture('sample_png.png'))
      expect(document.document_type).to have_attributes(
        name: 'Attachments',
        workgroup_id: workgroup.id,
        short_name: 'attachments'
      )
    end

    it 'removes custom field but keep its values' do
      expect { custom_field.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { custom_field_group.reload }.not_to raise_error
      expect { company.reload }.not_to(change { company.custom_field_values })
    end
  end

  context 'Chouette::StopArea' do
    let(:context) do
      Chouette.create do
        workbench organisation: Organisation.find_by(code: 'first') do
          stop_area :stop_area1, name: 'Stop Area one'
        end
      end
    end

    let(:workgroup) { context.workgroup }
    let(:workbench) { context.workbench }
    let(:referential) { context.referential }

    let(:custom_field_group) { workgroup.custom_field_groups.create!(name: 'Documents', resource_type: 'StopArea') }
    let(:custom_field) do
      workgroup.custom_fields.create!(
        code: 'plop',
        name: 'Attachments',
        resource_type: 'StopArea',
        field_type: 'attachment',
        custom_field_group: custom_field_group,
        options: { 'section' => 'identification' }
      )
    end

    let(:stop_area) do
      stop_area = context.stop_area(:stop_area1)
      stop_area = stop_area.class.find(stop_area.id)
      stop_area.update(custom_field_values: { plop: open_fixture('sample_png.png') })
      stop_area
    end

    before do
      custom_field
      stop_area
      subject
    end

    it 'creates a new document with the same content as the custom field' do
      document = stop_area.documents.first
      expect(document).to have_attributes(
        name: 'Attachments Stop Area one',
        document_provider_id: workbench.default_document_provider.id
      )
      expect(File.read(document.file.path)).to eq(read_fixture('sample_png.png'))
      expect(document.document_type).to have_attributes(
        name: 'Attachments',
        workgroup_id: workgroup.id,
        short_name: 'attachments'
      )
    end

    it 'removes custom field but keep its values' do
      expect { custom_field.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { custom_field_group.reload }.not_to raise_error
      expect { stop_area.reload }.not_to(change { stop_area.custom_field_values })
    end
  end
end
