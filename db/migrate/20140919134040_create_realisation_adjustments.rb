class CreateRealisationAdjustments < ActiveRecord::Migration
  def change
    create_table :realisation_adjustments do |t|
      t.integer :loan_id, null: false
      t.integer :amount, null: false
      t.date :date, null: false
      t.text :notes
      t.integer :created_by_id, null: false
      t.timestamps null: false
    end

    add_index :realisation_adjustments, :loan_id
    add_index :realisation_adjustments, :date
    add_index :realisation_adjustments, :created_by_id
  end
end
