# coding: utf-8
describe "Routes", :type => :feature do
  login_user

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by_code('first') do
        route
      end
    end
  end

  let(:referential) { context.referential }
  let(:line) { route.line }
  let(:route) { context.route }

  describe 'permissions' do
    before do
      @user.update(organisation: referential.organisation)
      allow_any_instance_of(RoutePolicy).to receive(:edit?).and_return permission
      allow_any_instance_of(RoutePolicy).to receive(:destroy?).and_return permission
      visit path
    end

    describe 'on show view' do
      let( :path ){ referential_line_route_path(referential, line, route) }

      context 'if present → ' do
        let( :permission ){ true }
        it 'view shows the corresponding buttons' do
          expected_edit_url   = edit_referential_line_route_path(referential, line, route)
          expected_delete_url = referential_line_route_path(referential, line, route)
          expect( page ).to have_link('Editer', href: expected_edit_url)
          expect( page ).to have_link('Supprimer', href: expected_delete_url)
        end
      end

      context 'if absent → ' do
        let( :permission ){ false }
        it 'view does not show the corresponding buttons' do
          expect( page ).not_to have_link('Editer')
          expect( page ).not_to have_link('Supprimer')
        end
      end
    end

  end
end
