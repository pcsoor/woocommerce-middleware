class AddNameToStore < ActiveRecord::Migration[8.0]
  def change
    add_column :stores, :name, :string
  end
end
