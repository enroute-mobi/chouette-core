
RSpec.describe PublicationApi, type: :model do
  subject { create(:publication_api) }

  it { is_expected.to belong_to(:workgroup).required(false) }
  it { should validate_presence_of :name }
  it { should validate_presence_of :slug }
  it { should validate_uniqueness_of :slug }

  let(:valid_slugs){ %w[demo demo2 demo_2]}
  let(:invalid_slugs){ ["demo 1", "démo"] }

  it 'validates slug format' do
    valid_slugs.each do |slug|
      subject.slug = slug
      expect(subject).to be_valid
    end

    invalid_slugs.each do |slug|
      subject.slug = slug
      expect(subject).to_not be_valid
    end
  end
end
