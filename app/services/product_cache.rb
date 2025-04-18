class ProductCache
  def self.key_for(user_id, product_id)
    "user:#{user_id}:product:#{product_id}"
  end
end
