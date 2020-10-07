FactoryBot.define do
  factory :import_message, class: Import::Message do
    association :import
    association :resource, factory: :import_resource
    criticity {:info}

    factory :corrupt_zip_file do
      message_key {'corrupt_zip_file'}
      message_attributes {{ source_filename: 'political file' }}
      criticity {:error}
    end

    factory :inconsistent_zip_file do
      message_key {'inconsistent_zip_file'}
      message_attributes {{ source_filename: 'robert talking', spurious_dirs: %w{dogs and cats}.join }}
      criticity {:warning}
    end
  end
end
