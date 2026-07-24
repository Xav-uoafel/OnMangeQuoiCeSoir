class CreateHouseholds < ActiveRecord::Migration[7.1]
  def change
    create_table :households do |t|
      t.string :name
      t.string :invite_code, null: false

      t.timestamps
    end

    add_index :households, :invite_code, unique: true
  end
end
