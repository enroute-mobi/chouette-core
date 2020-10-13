FactoryBot.define do
  factory :cross_referential_index_entry do
    parent_type {"MyString"}
    parent_id {1}
    target_type {"MyString"}
    target_id {1}
    target_referential_slug {"MyString"}
  end
end
