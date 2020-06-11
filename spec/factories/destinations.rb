FactoryGirl.define do
  factory :destination do
    association :publication_setup
    name "MyString"
    type "Destination::Dummy"
    options nil
    secret_file nil
  end

  factory :publication_api_destination, parent: :destination, class: 'Destination::PublicationApi'

  factory :destination_mail, parent: :destination, class: Destination::Mail do
    type "Destination::Mail"
    recipients ["test@mail.com"]
    email_title "Mail title"
    email_text "Mail text"
    attached_export_file false
  end
end
