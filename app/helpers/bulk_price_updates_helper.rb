module BulkPriceUpdatesHelper
  def price_update_status_badge(product)
    if product.valid?
      if product.has_warnings?
        content_tag :div, t('bulk_price_updates.status_badges.warning'), class: "badge badge-warning gap-2"
      else
        content_tag :div, t('bulk_price_updates.status_badges.valid'), class: "badge badge-success gap-2"
      end
    else
      content_tag :div, t('bulk_price_updates.status_badges.invalid'), class: "badge badge-error gap-2"
    end
  end

  def product_action_badge(product, existing_products, new_products)
    return content_tag(:div, t('bulk_price_updates.status_badges.skip'), class: "badge badge-ghost") unless product.valid?

    if existing_products.include?(product)
      content_tag :div, class: "badge badge-info gap-2" do
        concat icon("arrow-path", variant: :micro, class: "w-3 h-3")
        concat t('bulk_price_updates.status_badges.update')
      end
    elsif new_products.include?(product)
      content_tag :div, class: "badge badge-primary gap-2" do
        concat icon("plus", variant: :micro, class: "w-3 h-3") 
        concat t('bulk_price_updates.status_badges.create')
      end
    end
  end

  def product_price_display(price)
    if price.present? && price > 0
      content_tag :div, "#{price} Ft", class: "badge badge-outline"
    else
      content_tag :span, t('bulk_price_updates.product_fields.not_set'), class: "text-base-content/50 italic"
    end
  end

  def product_field_display(value, default_text = nil)
    if value.present?
      value
    else
      display_text = default_text || t('bulk_price_updates.product_fields.missing')
      content_tag :span, display_text, class: "text-base-content/50 italic"
    end
  end

  def product_issues_display(product)
    content_tag :div, class: "max-w-sm" do
      issues = []
      
      # Validation Errors
      if product.errors.any?
        product.errors.full_messages.each do |error_message|
          issues << content_tag(:div, error_message, class: "text-xs text-error")
        end
      end

      # Warnings
      if product.has_warnings?
        product.warnings.each do |warning|
          issues << content_tag(:div, warning, class: "text-xs text-warning")
        end
      end

      # No issues
      if product.valid? && !product.has_warnings?
        issues << content_tag(:span, t('bulk_price_updates.product_fields.ready_to_process'), class: "text-xs text-success")
      end

      safe_join(issues)
    end
  end

  def success_rate_color(rate)
    case rate
    when 0...50
      "text-error"
    when 50...80
      "text-warning"
    else
      "text-success"
    end
  end

  def format_file_timestamp(timestamp_string)
    return t('common.unknown') unless timestamp_string

    time = Time.parse(timestamp_string)
    time_ago_in_words(time)
  rescue ArgumentError
    t('common.unknown')
  end

  def total_processed_count(results)
    (results["updated_count"] || 0) + (results["created_count"] || 0)
  end
end
