module Support
  module DecoratorHelpers
    def self.included(into)
      into.instance_eval do
        subject{ object.decorate }
        let( :policy ){ ::Pundit.policy(user_context, object) }
        let( :user_context ){ UserContext.new(user, referential: referential) }
        let( :features ){ [] }
        let( :filtered_action_links){}
        before do
          allow(subject.h).to receive(:duplicate_workbench_referential_path).and_return new_workbench_referential_path(referential.workbench, from: referential.id)
          allow_any_instance_of(Draper::HelperProxy).to receive(:policy).and_return policy
          allow_any_instance_of(AF83::Decorator::Link).to receive(:check_feature){|f|
            features.include?(f)
          }
        end
      end
    end

    def expect_action_link_hrefs(action=:index)
      if subject.action_links.is_a? AF83::Decorator::ActionLinks
        expect( subject.action_links(action).map(&:href) )
      else
        expect( subject.action_links.select(&Link.method(:===)).map(&:href) )
      end
    end

    def expect_action_link_elements(action=:index)
      if subject.action_links.is_a? AF83::Decorator::ActionLinks
        expect( subject.action_links(action).map(&:content) )
      else
        expect( subject.action_links.select(&HTMLElement.method(:===)).map(&:content) )
      end
    end
  end
end
