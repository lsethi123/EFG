class CreateDataCorrectionsTable < ActiveRecord::Migration
  def up
    create_table :data_corrections do |t|
      t.belongs_to :loan, null: false
      t.belongs_to :created_by, null: false
      t.string     :change_type_id, null: false
      t.string     :oid
      t.integer    :seq, default: 0, null: false
      t.date       :date_of_change, null: false
      t.date       :modified_date, null: false
      t.string     :modified_user
      t.datetime   :ar_timestamp
      t.datetime   :ar_insert_timestamp
      t.text       :data_correction_changes

      # keep the old data in case we missed something
      t.string  :_legacy_business_name
      t.string  :_legacy_old_business_name
      t.date    :_legacy_facility_letter_date
      t.date    :_legacy_old_facility_letter_date
      t.string  :_legacy_sortcode
      t.string  :_legacy_old_sortcode
      t.integer :_legacy_dti_demand_outstanding,     :limit => 8
      t.integer :_legacy_old_dti_demand_outstanding, :limit => 8
      t.integer :_legacy_dti_interest,               :limit => 8
      t.integer :_legacy_old_dti_interest,           :limit => 8
      t.integer :_legacy_lending_limit_id
      t.integer :_legacy_old_lending_limit_id
      t.string  :_legacy_postcode
      t.string  :_legacy_old_postcode
      t.string  :_legacy_lender_reference
      t.string  :_legacy_old_lender_reference

      t.timestamps
    end

    add_index :data_corrections, [:loan_id, :seq], unique: true
  end

  def down
    drop_table :data_corrections
  end
end
