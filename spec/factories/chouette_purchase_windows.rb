FactoryBot.define do
  factory :purchase_window, class: Chouette::PurchaseWindow do
    sequence(:name) { |n| "Purchase Window #{n}" }
    sequence(:objectid) { |n| "organisation:PurchaseWindow:#{n}:LOC" }
    date_ranges { [generate(:periods)] }    
  end

  sequence :periods do |n|
    date = Date.today + 2*n
    date..(date+1)
  end
end
