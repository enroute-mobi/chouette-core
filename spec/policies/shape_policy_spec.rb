RSpec.describe ShapePolicy, type: :policy do


  let(:context) do
    Chouette.create { shape }
  end
  let(:record) { context.shape }
  # before(:each) { user.organisation = create(:organisation) }


  context 'Non Destructive actions →' do
    permissions :index? do
      it_behaves_like 'always allowed', 'anything'
    end
    permissions :show? do
      it_behaves_like 'always allowed', 'anything'
    end
  end


  context 'Destructive actions →' do
    let( :user_context_with_record_workbench ) { create_user_context(user, referential, context.workbench)  }

    permissions :create? do
      it_behaves_like 'always forbidden', 'shapes.create'

      context 'permission absent → ' do
        it "denies a user with a different organisation" do
          expect_it.not_to permit(user_context, record)
        end
        it 'and also a user with the same organisation' do
          user.organisation_id = record.shape_provider.workbench.organisation_id
          expect_it.not_to permit(user_context_with_record_workbench, record)
        end
      end

      context 'permission present → '  do
        before do
          add_permissions('shapes.create', to_user: user)
        end

        it 'denies a user with a different organisation' do
          expect_it.not_to permit(user_context, record)
        end

        it 'but allows it for a user with the same organisation' do
          user.organisation_id = record.shape_provider.workbench.organisation_id
          expect_it.to permit(user_context_with_record_workbench, record)
        end
      end
    end

    permissions :update? do
      context 'permission absent → ' do
        it "denies a user with a different organisation" do
          expect_it.not_to permit(user_context, record)
        end
        it 'and also a user with the same organisation' do
          user.organisation_id = record.shape_provider.workbench.organisation_id
          expect_it.not_to permit(user_context_with_record_workbench, record)
        end
      end

      context 'permission present → '  do
        before do
          add_permissions('shapes.update', to_user: user)
        end

        it 'denies a user with a different organisation' do
          expect_it.not_to permit(user_context, record)
        end

        it 'but allows it for a user with the same organisation' do
          user.organisation_id = record.shape_provider.workbench.organisation_id
          expect_it.to permit(user_context_with_record_workbench, record)
        end
      end
    end

    permissions :destroy? do
      context 'permission absent → ' do
        it "denies a user with a different organisation" do
          expect_it.not_to permit(user_context, record)
        end
        it 'and also a user with the same organisation' do
          user.organisation_id = record.shape_provider.workbench.organisation_id
          expect_it.not_to permit(user_context_with_record_workbench, record)
        end
      end

      context 'permission present → '  do
        before do
          add_permissions('shapes.destroy', to_user: user)
        end

        it 'denies a user with a different organisation' do
          expect_it.not_to permit(user_context, record)
        end

        it 'but allows it for a user with the same organisation' do
          user.organisation_id = record.shape_provider.workbench.organisation_id
          expect_it.to permit(user_context_with_record_workbench, record)
        end
      end
    end
  end

end
