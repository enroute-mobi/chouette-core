require 'spec_helper'

describe RouteDecorator do
  let(:object) { build_stubbed :route }
  let(:user) { build_stubbed :user }

  describe 'action links' do
    before do
      allow(helpers).to receive(:referential_line_route_vehicle_journey_exports_path).and_return('/rlrvje_path')
      allow(helpers).to receive(:referential_line_route_path).and_return('/rlr_path')
      allow(helpers).to receive(:destroy_link_content).and_return('destroy_link_content')
      allow(helpers).to receive(:duplicate_referential_line_route_path).and_return('/drlr_path')
    end

    context 'for authorized user' do
      before do
        stub_policy([duplicate?: true, destroy?: true])
      end

      it 'should render duplicate link' do
        expect(subject.action_links.map(&:content)).to include(I18n.t('routes.duplicate.title'))
        expect_action_link_hrefs.to include('/drlr_path')
      end

      it 'should render destroy link' do
        expect(subject.action_links.map(&:content)).to include('destroy_link_content')
        expect_action_link_hrefs.to include('/rlr_path')
      end
    end

    context 'for unauthorized user' do
      before do
        stub_policy([duplicate?: false, destroy?: false])
      end

      it 'should render duplicate link' do
        expect(subject.action_links.map(&:content)).to_not include(I18n.t('routes.duplicate.title'))
        expect_action_link_hrefs.to_not include('/drlr_path')
      end

      it 'should render destroy link' do
        expect(subject.action_links.map(&:content)).to_not include('destroy_link_content')
        expect_action_link_hrefs.to_not include('/rlr_path')
      end
    end
  end
end
