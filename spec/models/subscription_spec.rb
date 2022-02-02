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
    expect(subscription.user.profile).to eq 'admin'
  end

  context 'when workbench_confirmation_code is present' do
    let(:organisation) { FactoryBot.create(:organisation) }
    let(:workbench) { FactoryBot.create(:workbench, organisation_id: nil, prefix: nil, status: :pending, invitation_code: 'test') }

    it 'should not create a workgroup' do
      subscription = Subscription.new({
        user_name: "John Doe",
        email: "john.doe@example.com",
        password: "password",
        password_confirmation: "password",
        organisation_name: "The Daily Planet",
        workbench_confirmation_code: 'test'
      })

      expect { subscription.save }.to change { Workgroup.count }.by(0)
    end
    
    context 'code is valid' do
      it 'should attempt to accept invitation' do
        Workbench.first.update(invitation_code: 'test', status: :pending)

        subscription = Subscription.new({
          user_name: "John Doe",
          email: "john.doe@example.com",
          password: "password",
          password_confirmation: "password",
          organisation_name: "The Daily Planet",
          workbench_confirmation_code: 'test'
        })
        
        expect_any_instance_of(Workbenches::AcceptInvitation).to receive(:call)

        subscription.save
      end
    end
    
    context 'code is invalid' do
      it 'should not attempt to accept invitation' do
        subscription = Subscription.new({
          user_name: "John Doe",
          email: "john.doe@example.com",
          password: "password",
          password_confirmation: "password",
          organisation_name: "The Daily Planet",
          workbench_confirmation_code: 'test'
        })
        
        subscription.save

        expect_any_instance_of(Workbenches::AcceptInvitation).not_to receive(:call)
      end
    end
  end
end
