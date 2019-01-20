module MenusHelper
  def main_nav_menu_item label, &block
    @current_menu_item_count ||= 0
    @current_menu_item_count += 1
    id = "menu-item-#{@current_menu_item_count}"
    content_tag :div, class: "menu-item panel" do
      out = ""
      out += content_tag(:div, class: "panel-heading") do
        content_tag :h4, class: "panel-title" do
          link_to label, "#menu-item-#{@current_menu_item_count}", data: { toggle: 'collapse' }, 'aria-expanded' => 'false', 'aria-controls' => id
        end
      end
      out += content_tag(:div, class: "panel-collapse collapse", id: id) do
        content_tag :div, class: "list-group" do
          capture(&block)
        end
      end
      out.html_safe
    end
  end
end
