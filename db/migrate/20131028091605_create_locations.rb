class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations, :id => false do |t|
      t.integer :id, :null => false
      t.string :name

      t.timestamps
    end
  end
end
