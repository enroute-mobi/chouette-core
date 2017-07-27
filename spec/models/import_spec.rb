RSpec.describe Import, :type => :model do
  subject{ build_stubbed :import }
  it { should belong_to(:referential) }
  it { should belong_to(:workbench) }
  it { should belong_to(:parent).class_name(described_class.to_s) }

  it { should enumerize(:status).in("aborted", "analyzing", "canceled", "downloading", "failed", "new", "pending", "running", "successful") }

  it { should validate_presence_of(:file) }
end
