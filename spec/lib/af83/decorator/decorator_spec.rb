# frozen_string_literal: true

RSpec.describe AF83::Decorator do
  describe(:parse_options) do
    let(:options){
      {primary: true, secondary: %i(index show), policy: :blublu, weight: 12}
    }
    let(:link_options){
      {foo: :foo, bar: :bar}
    }
    let(:args){ options.dup.update(link_options.dup) }
    it "should separate options from link_options" do
      _options, _link_options = AF83::Decorator.instance_decorator.send :parse_options, args
      expect(_options).to eq({weight: 12})
      link_options.each do |k, v|
        expect(_link_options[k]).to eq v
      end
      expect(_link_options[:_groups][:primary]).to eq true
      expect(_link_options[:_groups][:secondary]).to eq %i(index show)
      expect(_link_options[:_policy]).to eq :blublu
    end
  end

  link_should_match_options = ->(link, options){
    options.each do |k, v|
      expect(link.send(k)).to eq v
    end
  }

  context "as an collection decorator" do
    let(:link_options) do
      {
        href: "/foo/bar",
        content: "Blublu"
      }
    end

    let(:decorator) do
      klass = Class.new(AF83::Decorator)
      klass.action_link link_options
      klass
    end

    let(:decorated) do
      3.times { create :line }
      decorator.decorate(Chouette::Line.all)
    end

    it "should return the links" do
      links = decorated.action_links
      instance_exec links.first, link_options, &link_should_match_options
    end
  end

  context "as an instance decorator" do
    describe("with the actual decorator") do
      before(:each) do
        Draper::HelperProxy.any_instance.stub(:policy){
          klass = Class.new do
            def method_missing *args
              true
            end
          end.new
        }
      end

      let(:decorated) do
        line = create :line
        line.decorate(context: {line_referential: line.line_referential})
      end

      it "should return the links" do
        expect{ decorated.action_links }.to_not raise_error
      end
    end

    describe(:action_links) do
      let(:decorated) do
        obj = create :line
        decorator.decorate(obj)
      end

      context "without links" do
        let(:decorator) do
          Class.new(AF83::Decorator)
        end

        it "should return no link" do
          links = decorated.action_links
          expect(links.size).to eq 0
        end
      end

      context "with a single link" do
        let(:link_options) do
          {
            href: "/foo/bar",
            content: "Blublu"
          }
        end

        context "incompletetly defined" do
          let(:decorator) do
            klass = Class.new(AF83::Decorator)
            klass.with_instance_decorator do |instance_decorator|
              instance_decorator.action_link href: "bar"
            end
            klass
          end

          it "should raise an error" do
            expect{decorator}.to raise_error(AF83::Decorator::IncompleteLinkDefinition)
          end
        end

        context "defined inline" do
          let(:decorator) do
            klass = Class.new(AF83::Decorator)
            klass.with_instance_decorator do |instance_decorator|
              instance_decorator.action_link link_options
            end
            klass
          end

          it "should return the defined link" do
            links = decorated.action_links
            expect(links.size).to eq 1
            instance_exec links.first, link_options, &link_should_match_options
          end
        end

        context "defined in a block" do
          let(:decorator) do
            klass = Class.new(AF83::Decorator)
            klass.with_instance_decorator do |instance_decorator|
              instance_decorator.action_link do |l|
                l.href link_options[:href]
                l.content link_options[:content]
              end
            end
            klass
          end

          it "should return the defined link" do
            links = decorated.action_links
            expect(links.size).to eq 1
            instance_exec links.first, link_options, &link_should_match_options
          end
        end

        context "with proc attributes" do
          let(:decorator) do
            klass = Class.new(AF83::Decorator)
            klass.with_instance_decorator do |instance_decorator|
              instance_decorator.action_link do |l|
                l.href { context[:href] }
                l.content "Blublu"
              end
            end
            klass
          end

          let(:decorated) do
            obj = create :line
            decorator.decorate(obj, context: {href: link_options[:href]})
          end

          it "should return the defined link" do
            links = decorated.action_links
            expect(links.size).to eq 1
            expect(links.first.href).to eq link_options[:href]
          end
        end

        context "with a method attributes" do
          let(:decorator) do
            klass = Class.new(AF83::Decorator)
            klass.with_instance_decorator do |instance_decorator|
              instance_decorator.action_link do |l|
                l.href "/foo/bar"
                l.content "Blublu"
                l.method :put
              end
            end
            klass
          end

          let(:decorated) do
            obj = create :line
            decorator.decorate(obj, context: {href: link_options[:href]})
          end

          it "should return the defined method" do
            links = decorated.action_links
            expect(links.size).to eq 1
            expect(links.first.method).to eq :put
          end
        end
      end

      context "with 2 links" do
        let(:link_options_1) do
          {
            href: "/foo/bar",
            content: "Blublu"
          }
        end

        let(:link_options_2) do
          {
            href: "/foo/bar/baz",
            content: "Foo"
          }
        end

        context "without weight" do
          let(:decorator) do
            klass = Class.new(AF83::Decorator)
            klass.with_instance_decorator do |instance_decorator|
              instance_decorator.action_link link_options_1
              instance_decorator.action_link link_options_2
            end
            klass
          end

          it "should return links in the sequence they were defined" do
            links = decorated.action_links
            expect(links.size).to eq 2
            instance_exec links.first, link_options_1, &link_should_match_options
            instance_exec links.last, link_options_2, &link_should_match_options
          end
        end

        context "with weight" do
          let(:decorator) do
            klass = Class.new(AF83::Decorator)
            klass.with_instance_decorator do |instance_decorator|
              instance_decorator.action_link link_options_1.update(weight: 10)
              instance_decorator.action_link link_options_2
            end
            klass
          end

          it "should return links in the correct sequence" do
            links = decorated.action_links
            expect(links.size).to eq 2
            instance_exec links.first, link_options_2, &link_should_match_options
            instance_exec links.last, link_options_1, &link_should_match_options
          end
        end

        context "scoped by action" do
          let(:decorator) do
            klass = Class.new(AF83::Decorator)
            klass.with_instance_decorator do |instance_decorator|
              instance_decorator.action_link link_options_1.update(action: :index)
              instance_decorator.action_link link_options_2
            end
            klass
          end

          it "should only return links defined for the given action" do
            links = decorated.action_links(:show)
            expect(links.size).to eq 1
            instance_exec links.first, link_options_2, &link_should_match_options
          end
        end

        context "with a policy" do
          let(:decorator) do
            klass = Class.new(AF83::Decorator)
            klass.with_instance_decorator do |instance_decorator|
              instance_decorator.action_link href: "foo", content: "foo", policy: :edit
            end
            klass
          end

          context "when the policy is not met" do
            before(:each) do
              Draper::HelperProxy.any_instance.stub(:policy){
                klass = Class.new do
                  def edit?
                    false
                  end
                end.new
              }
            end

            it "should not return the link" do
              links = decorated.action_links(:show)
              expect(links.size).to eq 0
            end
          end

          context "when the policy is met" do
            before(:each) do
              Draper::HelperProxy.any_instance.stub(:policy){
                klass = Class.new do
                  def edit?
                    true
                  end
                end.new
              }
            end

            it "should not return the link" do
              links = decorated.action_links(:show)
              expect(links.size).to eq 1
            end
          end
        end

        context "with a feature" do
          let(:decorator) do
            klass = Class.new(AF83::Decorator)
            klass.with_instance_decorator do |instance_decorator|
              instance_decorator.action_link href: "foo", content: "foo", feature: :foo
            end
            klass
          end

          context "when the feature is not present" do
            before(:each) do
              Draper::HelperProxy.any_instance.stub(:has_feature?){false}
            end

            it "should not return the link" do
              links = decorated.action_links(:show)
              expect(links.size).to eq 0
            end
          end

          context "when the feature is present" do
            before(:each) do
              Draper::HelperProxy.any_instance.stub(:has_feature?){true}
            end

            it "should not return the link" do
              links = decorated.action_links(:show)
              expect(links.size).to eq 1
            end
          end
        end

        context "with a condition" do
          context "set with 'with_condition'" do
            context "as a value" do
              context "when the condition is true" do
                let(:decorator) do
                  klass = Class.new(AF83::Decorator)
                  klass.with_instance_decorator do |instance_decorator|
                    instance_decorator.with_condition true do
                      action_link href: "foo", content: "foo"
                    end
                  end
                  klass
                end

                it "should return the link" do
                  links = decorated.action_links(:show)
                  expect(links.size).to eq 1
                end
              end

              context "when the condition is false" do
                let(:decorator) do
                  klass = Class.new(AF83::Decorator)
                  klass.with_instance_decorator do |instance_decorator|
                    instance_decorator.with_condition false do
                      action_link href: "foo", content: "foo"
                    end
                  end
                  klass
                end

                it "should not return the link" do
                  links = decorated.action_links(:show)
                  expect(links.size).to eq 0
                end
              end
            end

            context "as a Proc" do
              let(:decorator) do
                klass = Class.new(AF83::Decorator)
                klass.with_instance_decorator do |instance_decorator|
                  instance_decorator.with_condition ->{context[:show_link]} do
                    action_link href: "foo", content: "foo"
                  end
                end
                klass
              end

              context "when the condition is true" do
                let(:decorated) do
                  obj = create :line
                  decorator.decorate(obj, context: {show_link: true})
                end

                it "should return the link" do
                  links = decorated.action_links(:show)
                  expect(links.size).to eq 1
                end
              end

              context "when the condition is false" do
                let(:decorated) do
                  obj = create :line
                  decorator.decorate(obj, context: {show_link: false})
                end

                it "should not return the link" do
                  links = decorated.action_links(:show)
                  expect(links.size).to eq 0
                end
              end
            end
          end

          context "set inline" do
            context "as a value" do
              context "when the condition is true" do
                let(:decorator) do
                  klass = Class.new(AF83::Decorator)
                  klass.with_instance_decorator do |instance_decorator|
                    instance_decorator.action_link link_options_1.update(if: true)
                  end
                  klass
                end

                it "should return the link" do
                  links = decorated.action_links(:show)
                  expect(links.size).to eq 1
                end
              end

              context "when the condition is false" do
                let(:decorator) do
                  klass = Class.new(AF83::Decorator)
                  klass.with_instance_decorator do |instance_decorator|
                    instance_decorator.action_link link_options_1.update(if: false)
                  end
                  klass
                end

                it "should not return the link" do
                  links = decorated.action_links(:show)
                  expect(links.size).to eq 0
                end
              end
            end

            context "as a Proc" do
              let(:decorator) do
                klass = Class.new(AF83::Decorator)
                klass.with_instance_decorator do |instance_decorator|
                  instance_decorator.action_link link_options_1.update(if: ->{context[:show_link]})
                end
                klass
              end

              context "when the condition is true" do
                let(:decorated) do
                  obj = create :line
                  decorator.decorate(obj, context: {show_link: true})
                end

                it "should return the link" do
                  links = decorated.action_links(:show)
                  expect(links.size).to eq 1
                end
              end

              context "when the condition is false" do
                let(:decorated) do
                  obj = create :line
                  decorator.decorate(obj, context: {show_link: false})
                end

                it "should not return the link" do
                  links = decorated.action_links(:show)
                  expect(links.size).to eq 0
                end
              end
            end
          end
        end

        context "scoped by action" do
          context "with a single action" do
            let(:decorator) do
              klass = Class.new(AF83::Decorator)
              klass.with_instance_decorator do |instance_decorator|
                instance_decorator.action_link link_options_1.update(action: :index)
                instance_decorator.action_link link_options_2
              end
              klass
            end

            it "should only return links defined for the given action" do
              links = decorated.action_links(:show)
              expect(links.size).to eq 1
              instance_exec links.first, link_options_2, &link_should_match_options
            end
          end

          context "with several actions" do
            let(:decorator) do
              klass = Class.new(AF83::Decorator)
              klass.with_instance_decorator do |instance_decorator|
                instance_decorator.action_link link_options_1.update(actions: %i(index edit))
                instance_decorator.action_link link_options_2.update(actions: %i(show edit))
              end
              klass
            end

            it "should only return links defined for the given action" do
              links = decorated.action_links(:show)
              expect(links.size).to eq 1
              instance_exec links.first, link_options_2, &link_should_match_options
            end
          end

          context "with the keyword 'on'" do
            let(:decorator) do
              klass = Class.new(AF83::Decorator)
              klass.with_instance_decorator do |instance_decorator|
                instance_decorator.action_link link_options_1.update(on: %i(index edit))
                instance_decorator.action_link link_options_2.update(on: :show)
              end
              klass
            end

            it "should only return links defined for the given action" do
              links = decorated.action_links(:show)
              expect(links.size).to eq 1
              instance_exec links.first, link_options_2, &link_should_match_options
            end
          end
        end
      end
    end

    describe '#primary' do
      let(:decorator) do
        Class.new(AF83::Decorator)
      end

      let(:decorated) do
        obj = create :line
        decorator.decorate(obj)
      end

      it "should return a new object everytime" do
        actions = decorated.action_links
        primary = actions.primary
        expect(actions.options[:groups]).to be_nil
        expect(primary.options[:groups]).to_not be_nil
      end
    end

    describe(:primary_links) do
      let(:decorated) do
        obj = create :line
        decorator.decorate(obj)
      end

      context "without links" do
        let(:decorator) do
          Class.new(AF83::Decorator)
        end

        it "should return no link" do
          links = decorated.action_links
          expect(links.size).to eq 0
        end
      end

      context "with a single link" do
        let(:link_options) do
          {
            href: "/foo/bar/baz",
            content: "Blublu",
            primary: primary
          }
        end

        let(:decorator) do
          klass = Class.new(AF83::Decorator)
          klass.with_instance_decorator do |instance_decorator|
            instance_decorator.action_link link_options
          end
          klass
        end

        context "always primary" do
          let(:primary){ true }

          it "should return the link" do
            links = decorated.primary_links(:show)
            expect(links.size).to eq 1
          end
        end

        context "primary on this action" do
          let(:primary){ :show }

          it "should return the link" do
            links = decorated.primary_links(:show)
            expect(links.size).to eq 1
          end
        end

        context "primary on this action among others" do
          let(:primary){ %i(show edit) }

          it "should return the link" do
            links = decorated.action_links(:show, group: :primary)
            expect(links.size).to eq 1
          end
        end

        context "primary on other actions" do
          let(:primary){  %i(index edit) }

          it "should not return the link" do
            links = decorated.action_links(:show, group: :primary)
            expect(links.size).to eq 0
          end
        end

        context "primary on another action" do
          let(:primary){  :index }

          it "should not return the link" do
            links = decorated.primary_links(:show)
            expect(links.size).to eq 0
          end
        end

        context "never primary" do
          let(:primary){ nil }

          it "should not return the link" do
            links = decorated.primary_links(:show)
            expect(links.size).to eq 0
          end
        end
      end
    end

    describe("in a group") do
      let(:decorated) do
        obj = create :line
        decorator.decorate(obj)
      end

      context "without links" do
        let(:decorator) do
          Class.new(AF83::Decorator)
        end

        it "should return no link" do
          links = decorated.action_links
          expect(links.size).to eq 0
        end
      end


      context "with a single link" do
        let(:link_options) do
          {
            href: "/foo/bar/baz",
            content: "Blublu",
            groups: {foo: group}
          }
        end

        let(:decorator) do
          klass = Class.new(AF83::Decorator)
          klass.with_instance_decorator do |instance_decorator|
            instance_decorator.action_link link_options
          end
          klass
        end

        context "always in" do
          let(:group){ true }

          it "should return the link" do
            links = decorated.action_links(:show, group: :foo)
            expect(links.size).to eq 1
          end

          context "define with group" do
            let(:link_options) do
              {
                href: "/foo/bar/baz",
                content: "Blublu",
                group: :foo
              }
            end

            let(:decorator) do
              klass = Class.new(AF83::Decorator)
              klass.with_instance_decorator do |instance_decorator|
                instance_decorator.action_link link_options
              end
              klass
            end

            it "should return the link" do
              links = decorated.action_links(:show, group: :foo)
              expect(links.size).to eq 1
            end

            it "should not return the link" do
              links = decorated.action_links(:show, group: :bar)
              expect(links.size).to eq 0
            end
          end
        end

        context "primary on this action" do
          let(:group){ :show }

          it "should return the link" do
            links = decorated.action_links(:show, group: :foo)
            expect(links.size).to eq 1
          end
        end

        context "in this action among others" do
          let(:group){ %i(show edit) }

          it "should return the link" do
            links = decorated.action_links(:show, group: :foo)
            expect(links.size).to eq 1
          end
        end

        context "in other actions" do
          let(:group){  %i(index edit) }

          it "should not return the link" do
            links = decorated.action_links(:show, group: :foo)
            expect(links.size).to eq 0
          end
        end

        context "in another action" do
          let(:group){  :index }

          it "should not return the link" do
            links = decorated.action_links(:show, group: :foo)
            expect(links.size).to eq 0
          end
        end

        context "never" do
          let(:group){ nil }

          it "should not return the link" do
            links = decorated.action_links(:show, group: :foo)
            expect(links.size).to eq 0
          end
        end
      end

      describe(:grouped_by) do
        let(:link_options_1) do
          {
            href: "/foo/bar",
            content: "Blublu",
            primary: true
          }
        end

        let(:link_options_2) do
          {
            href: "/foo/bar/baz",
            content: "Foo",
            groups: {secondary: :show}
          }
        end

        let(:link_options_3) do
          {
            href: "/foo/bar/baz/bat",
            content: "Foo",
            groups: {foo: :show}
          }
        end

        let(:link_options_4) do
          {
            href: "/footer",
            content: "Foo",
            footer: true
          }
        end

        let(:decorator) do
          klass = Class.new(AF83::Decorator)
          klass.with_instance_decorator do |instance_decorator|
            instance_decorator.action_link link_options_1
            instance_decorator.action_link link_options_2
            instance_decorator.action_link link_options_3
            instance_decorator.action_link link_options_4
          end
          klass
        end

        it "should return links in their groups" do
          links = decorated.action_links(:show).grouped_by(:primary, :secondary, :blu, :footer)
          expect(links.size).to eq 5
          instance_exec links[:primary].first, link_options_1, &link_should_match_options
          instance_exec links[:secondary].first, link_options_2, &link_should_match_options
          expect(links[:blu].size).to eq 0
          instance_exec links[:other].first, link_options_3, &link_should_match_options
          instance_exec links[:footer].first, link_options_4, &link_should_match_options
        end
      end
    end
  end
end
