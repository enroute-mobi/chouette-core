FactoryBot.define do
  factory :compliance_check_message do
    association :compliance_check
    association :compliance_check_resource
    association :compliance_check_set
    status {'OK'}
    message_key {"message_key"}
  end
end
