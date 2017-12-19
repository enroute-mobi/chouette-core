module Support
  module LineReferentialControllerHelper

    def it_should_redirect_to_forbidden desc, ok_status: nil, &example
      context 'line_referential does not belong to the current orgnisation' do
        it "nok: #{desc}" do
          instance_exec(&example)
          expect( response ).to redirect_to(forbidden_path)
        end
      end

      context 'line_referential belongs to organisation (habtm via LineReferentialMembership)' do
        it "ok: #{desc}" do
          @user.organisation.line_referentials << line_referential
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
  conf.extend Support::LineReferentialControllerHelper, type: :controller
end
