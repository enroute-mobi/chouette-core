describe Subscription, type: :model do
  it "creates an Organisation with all features" do
    subscription = Subscription.new organisation_name: "organisation_test"
    expect(subscription.organisation.features).to match_array(Feature.all)
  end

  it "should validate the email format" do
    subscription = Subscription.new({
      user_name: "John Doe",
      email: "john.doe@+example.com",
      password: "password",
      password_confirmation: "password",
      organisation_name: "The Daily Planet"
    })

    expect(subscription.valid?).to be_falsy
  end

  it "should create an organisation" do
    subscription = Subscription.new({
      user_name: "John Doe",
      email: "john.doe@example.com",
      password: "password",
      password_confirmation: "password",
      organisation_name: "The Daily Planet"
    })

    expect(subscription.valid?).to be_truthy
    expect{subscription.save}.to change{ Workgroup.count }.by 1
    expect(subscription.workgroup.owner).to eq subscription.organisation
    expect(subscription.workgroup.export_types).to include "Export::Gtfs"
    expect(subscription.workgroup.export_types).to include "Export::NetexFull"
    expect(subscription.user.profile).to eq 'admin'
  end
end
