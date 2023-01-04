# frozen_string_literal: true

RSpec.describe OperationsHelper::UserStatusRenderer do
  let(:user_status) { Operation.user_status.pending }
  subject(:renderer) { OperationsHelper::UserStatusRenderer.new user_status }

  describe 'icon_class' do
    subject { renderer.icon_class }

    [
      ['pending', 'fa-clock pending'],
      ['successful', 'fa-circle text-success'],
      ['warning', 'fa-circle text-warning'],
      ['failed', 'fa-circle text-danger']
    ].each do |user_status, expected|
      context "when user status is #{user_status}" do
        let(:user_status) { Operation.user_status.find_value(user_status) }
        it { is_expected.to eq(expected) }
      end
    end
  end
end
