FactoryGirl.define do
  factory :referential_metadata, :class => 'ReferentialMetadata' do
    referential
    periodes { [ generate(:period) ] }
    lines { create_list(:line, 3) }

    after(:create) do |metadata|
      if metadata.referential&.line_referential_id&.present?
        metadata.lines.update_all line_referential_id: metadata.referential.line_referential_id
      end
    end
  end

  sequence :period do |n|
    date = Date.today + 2*n
    date..(date+1)
  end
end
