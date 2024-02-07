# frozen_string_literal: true

RSpec.describe AF83::Decorator::Link do
  describe "#complete?" do
    context "on a imcomplete link" do
      it "should be false" do
        expect(AF83::Decorator::Link.new.complete?).to be_falsy
        expect(AF83::Decorator::Link.new(content: "foo").complete?).to be_falsy
        expect(AF83::Decorator::Link.new(href: "foo").complete?).to be_falsy
      end
    end

    context "on a complete link" do
      it "should be true" do
        expect(AF83::Decorator::Link.new(href: "foo", content: "foo").complete?).to be_truthy
      end
    end
  end

  describe "#class" do
    let(:link){
      AF83::Decorator::Link.new(href: "foo", content: "foo", class: "initial_class")
    }

    it "should override exisiting class" do
      expect(link.html_options[:class]).to eq "initial_class"
      link.class "new_class"
      expect(link.html_options[:class]).to eq "new_class"
      link.class = "another_class"
      expect(link.html_options[:class]).to eq "another_class"
      link.class = %w(foo bar)
      expect(link.html_options[:class]).to eq "foo bar"
    end
  end

  describe "#add_class" do
    let(:link){
      AF83::Decorator::Link.new(href: "foo", content: "foo", class: "initial_class")
    }

    it "should add to exisiting class" do
      expect(link.html_options[:class]).to eq "initial_class"
      link.add_class "new_class"
      expect(link.html_options[:class]).to eq "initial_class new_class"
      link.add_class "another_class"
      expect(link.html_options[:class]).to eq "initial_class new_class another_class"
      link.add_class %w(foo bar)
      expect(link.html_options[:class]).to eq "initial_class new_class another_class foo bar"
    end
  end

  describe "#type" do

    let(:link){
      AF83::Decorator::Link.new(href: "foo", content: "foo")
    }

    let(:context){
      Class.new do
        def h
          Class.new do
            def link_to *args
              HTMLElement.new(:a, 'foo', {}).to_html
            end
          end.new
        end
      end.new
    }

    it "should allow for buttons" do
      link.type = :button
      expect(link.to_html).to match /\<button.*\<\/button\>/
    end

    it "should fallback to <a>" do
      link.type = :spaghetti
      link.bind_to_context context, :show
      expect(link.to_html).to match /\<a.*\<\/a\>/
    end
  end
end
