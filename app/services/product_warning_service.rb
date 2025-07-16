class ProductWarningService
  def self.call(product, user)
    new(product, user).call
  end

  def initialize(product, user)
    @product = product
    @user = user
  end

  def call
    return unless @product.valid?

    add_data_warnings
    add_action_warnings
  end

  private

  def add_data_warnings
    @product.add_warning(I18n.t('bulk_price_updates.product_fields.no_name_provided')) if @product.name.blank?
    @product.add_warning(I18n.t('bulk_price_updates.product_fields.no_price_provided')) if invalid_price?
  end

  def add_action_warnings
    if product_exists_in_woocommerce?
      @product.add_warning(I18n.t('bulk_price_updates.product_fields.will_update_existing'))
    else
      @product.add_warning(I18n.t('bulk_price_updates.product_fields.will_create_new'))
    end
  end

  def invalid_price?
    @product.regular_price.blank? || @product.regular_price <= 0
  end

  def product_exists_in_woocommerce?
    WoocommerceSkuChecker.call(@product.sku, @user.store)
  end
end 