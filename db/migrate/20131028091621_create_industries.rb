class CreateIndustries < ActiveRecord::Migration
  def change
    create_table :industries, :id => false do |t|
      t.integer :id, :null => false
      t.string :name

      t.timestamps
    end
  end
end
