class CreateSubLenders < ActiveRecord::Migration
  def change
    create_table :sub_lenders do |t|
      t.belongs_to :lender, null: false
      t.string :name
      t.timestamps
    end

    add_index :sub_lenders, :lender_id
  end
end
