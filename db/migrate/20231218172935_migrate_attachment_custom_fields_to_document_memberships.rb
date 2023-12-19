# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity,Metrics/BlockLength
class MigrateAttachmentCustomFieldsToDocumentMemberships < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      Workgroup.includes(:workbenches).find_in_batches(batch_size: 100) do |b|
        custom_fields = CustomField.where(workgroup_id: b.map(&:id), field_type: 'attachment').group_by(&:workgroup_id)

        b.each do |workgroup|
          workgroup_custom_fields = custom_fields[workgroup.id]&.group_by(&:resource_type)
          next unless workgroup_custom_fields&.any?

          workgroup.workbenches.each do |workbench|
            workgroup_document_types = Hash.new do |h, cf|
              h[cf] = workgroup.document_types.create!(
                name: cf.name,
                short_name: cf.name.underscore
              )
            end

            workgroup_custom_fields.each do |resource_type, cfs|
              workbench.send(resource_type.underscore.pluralize).find_each do |resource|
                cfs.each do |cf|
                  file = resource.send("custom_field_#{cf.code}")
                  file.cache!
                  File.open(file.path) do |f|
                    document = workbench.default_document_provider.documents.create!(
                      name: "#{cf.name} #{resource.name}",
                      file: f,
                      document_type: workgroup_document_types[cf]
                    )
                    resource.documents << document
                  end
                end
              end
            end
          end

          workgroup_custom_fields.each_value do |cfs|
            cfs.each(&:destroy)
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity,Metrics/BlockLength
