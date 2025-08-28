module CategoriesHelper
  def render_categories_tree(categories, categories_by_parent, level = 0)
    safe_join(categories.map do |category|
      render_category_row(category, level) +
        render_categories_tree(categories_by_parent[category.id] || [], categories_by_parent, level + 1)
    end)
  end

  def render_category_row(category, level = 0)
    indent_px = level * 20 # More flexible: control indentation in px

    content_tag :tr, class: "hover:bg-gray-100" do
      safe_join([
        content_tag(:td, class: "px-4 py-2 font-medium") do
          content_tag(:span, "↳", style: "margin-left: #{indent_px}px;", class: "text-gray-500") + " " + category.name
        end,
        content_tag(:td, category.slug, class: "px-4 py-2"),
        content_tag(:td, category.count, class: "px-4 py-2"),
        content_tag(:td, class: "px-4 py-2") do
          link_to "Edit", edit_category_path(category.id), class: "link"
        end
      ])
    end
  end
end
