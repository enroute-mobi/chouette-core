require 'spec_helper'

describe RoutingConstraintZoneDecorator do
  let(:object) { build_stubbed :routing_constraint_zone }
  let(:user) { build_stubbed :user }

  describe 'action links' do
    before do
      allow(helpers).to receive(:edit_referential_line_routing_constraint_zone_path).and_return('/edit_path')
      allow(helpers).to receive(:referential_line_routing_constraint_zone_path).and_return('/show_path')
      allow(helpers).to receive(:destroy_link_content).and_return('destroy_link_content')
    end

    context 'for authorized user' do
      before do
        stub_policy([update?: true, destroy?: true])
      end

      it 'should render edit link' do
        expect(subject.action_links.map(&:content)).to include(I18n.t('actions.edit'))
        expect_action_link_hrefs.to include('/edit_path')
      end

      it 'should render destroy link' do
        expect(subject.action_links.map(&:content)).to include('destroy_link_content')
      end
    end

    context 'for unauthorized user' do
      before do
        stub_policy([update?: false, destroy?: false])
      end

      it 'should not render edit link' do
        expect(subject.action_links.map(&:content)).to_not include(I18n.t('actions.edit'))
        expect_action_link_hrefs.to_not include('/edit_path')
      end

      it 'should not render destroy link' do
        expect(subject.action_links.map(&:content)).to_not include('destroy_link_content')
      end
    end
  end
end
