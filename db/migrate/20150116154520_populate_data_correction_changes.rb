class PopulateDataCorrectionChanges < ActiveRecord::Migration
  def up
    columns_to_migrate = [
      OpenStruct.new(name: "business_name", old_column: "_legacy_old_business_name", new_column: "_legacy_business_name"),
      OpenStruct.new(name: "facility_letter_date", old_column: "_legacy_old_facility_letter_date", new_column: "_legacy_facility_letter_date"),
      OpenStruct.new(name: "sortcode", old_column: "_legacy_old_sortcode", new_column: "_legacy_sortcode"),
      OpenStruct.new(name: "dti_demand_outstanding", old_column: "_legacy_old_dti_demand_outstanding", new_column: "_legacy_dti_demand_outstanding"),
      OpenStruct.new(name: "dti_interest", old_column: "_legacy_old_dti_interest", new_column: "_legacy_dti_interest"),
      OpenStruct.new(name: "lending_limit_id", old_column: "_legacy_old_lending_limit_id", new_column: "_legacy_lending_limit_id"),
      OpenStruct.new(name: "postcode", old_column: "_legacy_old_postcode", new_column: "_legacy_postcode"),
      OpenStruct.new(name: "lender_reference", old_column: "_legacy_old_lender_reference", new_column: "_legacy_lender_reference"),
    ]

    DataCorrection.all.each do |data_correction|
      extracted_changes = columns_to_migrate.each_with_object({}) do |attribute, memo|
        old_value = data_correction.public_send(attribute.old_column)
        new_value = data_correction.public_send(attribute.new_column)
        memo[attribute.name] = [ old_value, new_value ] if new_value or old_value
      end

      if extracted_changes.any?
        existing_changes = data_correction.data_correction_changes ||= {}
        data_correction.data_correction_changes = existing_changes.merge(extracted_changes)
        data_correction.save!
      end
    end
  end

  def down
  end
end
