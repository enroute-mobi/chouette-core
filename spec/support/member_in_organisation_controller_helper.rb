module Support
  module MemberInOrganisationControllerHelper

    def it_should_redirect_to_forbidden desc, 
      member_model:,
      member_model_assoc: nil,
      ok_status: nil,
      &example
      context "#{member_model} does not belong to the current orgnisation" do
        it "nok: #{desc}" do
          instance_exec(&example)
          expect( response ).to redirect_to(forbidden_path)
        end
      end

      context "#{member_model} belongs to organisation (habtm via LineReferentialMembership)" do
        it "ok: #{desc}" do
          model = send(member_model)
          @user.organisation.send(member_model_assoc || member_model.to_s.pluralize) << model
          instance_exec(&example)
          if ok_status 
            expect( response.status ).to eq(ok_status)
          else
            expect( response ).to be_success
          end
        end
      end
    end

  end
end

RSpec.configure do | conf |
  conf.extend Support::MemberInOrganisationControllerHelper, type: :controller
end
