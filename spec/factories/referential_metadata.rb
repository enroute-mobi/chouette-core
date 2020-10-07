FactoryBot.define do
  factory :referential_metadata, :class => 'ReferentialMetadata' do
    referential
    periodes { [ Date.today.beginning_of_year..Date.today.end_of_year ] }
    lines { create_list(:line, 3) }
  end

  sequence :period do |n|
    date = Date.today + 2*n
    date..(date+10)
  end
end
