# frozen_string_literal: true

RSpec.describe DocumentMembership, type: :model do
  it { should belong_to(:document).required }
  it { should belong_to(:documentable).required }
end
