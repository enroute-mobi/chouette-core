require 'spec_helper'

describe ComplianceControlSetDecorator do
  let(:object) { build_stubbed :compliance_control_set }
  let(:user) { build_stubbed :user }

  describe 'action links' do
    before do
      allow(helpers).to receive(:edit_compliance_control_set_path).and_return('/edit_path')
      allow(helpers).to receive(:clone_compliance_control_set_path).and_return('/clone_path')
      allow(helpers).to receive(:compliance_control_set_path).and_return('/show_path')
      allow(helpers).to receive(:destroy_link_content).and_return('destroy_link_content')
    end

    context 'for authorized user' do
      before do
        stub_policy([clone?: true, update?: true, destroy?: true])
      end

      it 'should render clone link' do
        expect(subject.action_links.map(&:content)).to include(I18n.t('actions.clone'))
        expect_action_link_hrefs.to include('/clone_path')
      end

      it 'should render edit link' do
        expect(subject.action_links.map(&:content)).to include(I18n.t('compliance_control_sets.actions.edit'))
        expect_action_link_hrefs.to include('/edit_path')
      end

      it 'should render destroy link' do
        expect(subject.action_links.map(&:content)).to include('destroy_link_content')
      end
    end

    context 'for unauthorized user' do
      before do
        stub_policy([clone?: false, update?: false, destroy?: false])
      end

      it 'should not render clone link' do
        expect(subject.action_links.map(&:content)).to_not include(I18n.t('actions.clone'))
        expect_action_link_hrefs.to_not include('/clone_path')
      end

      it 'should not render edit link' do
        expect(subject.action_links.map(&:content)).to_not include(I18n.t('compliance_control_sets.actions.edit'))
        expect_action_link_hrefs.to_not include('/edit_path')
      end

      it 'should not render destroy link' do
        expect(subject.action_links.map(&:content)).to_not include('destroy_link_content')
      end
    end
  end

end
