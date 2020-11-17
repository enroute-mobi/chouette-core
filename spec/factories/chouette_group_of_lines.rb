FactoryBot.define do

  factory  :group_of_line, :class => Chouette::GroupOfLine do
    sequence(:name) { |n| "Group Of Line #{n}" }
    sequence(:objectid) { |n| "STIF:CODIFLIGNE:GroupOfLine:#{n}" }
    sequence(:registration_number) { |n| "#{n}" }

    association :line_referential
    line_provider { association :line_provider, line_referential: line_referential }
    # association :line_provider, :factory => :line_provider, line_referential: line_referential
  end

end
