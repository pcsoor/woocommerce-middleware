class CreateStores < ActiveRecord::Migration[8.0]
  def change
    create_table :stores do |t|
      t.references :user, null: false, foreign_key: true
      t.string :api_url
      t.string :consumer_key
      t.string :consumer_secret

      t.timestamps
    end
  end
end
