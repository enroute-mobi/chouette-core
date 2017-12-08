module Support

  module DecoratorHelpers
    def self.included(into)
      into.instance_eval do
        subject{ object.decorate }
        let( :policy ){ ::Pundit.policy(user_context, object) }
        let( :user_context ){ UserContext.new(user, referential: referential) }

        before do
          allow_any_instance_of(Draper::HelperProxy).to receive(:policy).and_return policy
        end
      end
    end

    def stub_policy(actions)
      allow(helpers).to receive(:policy).and_return(double("policy", *actions))
    end

    def expect_action_link_hrefs
      expect( subject.action_links.select(&Link.method(:===)).map(&:href) )
    end
    def expect_action_link_elements
      expect( subject.action_links.select(&HTMLElement.method(:===)).map(&:content) )
    end
  end
end

RSpec.configure do | c |
  c.include Support::DecoratorHelpers, type: :decorator
end
