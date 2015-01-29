# This is intended to provide a mechanism by which relatively expensive data
# updates can be decoupled from deployment time and run independently.
#
# This will execute within an ActiveRecord transaction and is instance_eval-ed.
# Just write normal ruby code and refer to any model objects that you require.
# Since a data migration is intended to be run in production, when the schema
# and model are known quantities, it should be fine to reference model classes
# directly, even though in the future they may be refactored or deleted
# entirely.

# Set the correct change type on sort code data corrections
# but only if they don't have any other data corrections
fields = [
  :_legacy_business_name,
  :_legacy_old_business_name,
  :_legacy_facility_letter_date,
  :_legacy_old_facility_letter_date,
  :_legacy_dti_demand_outstanding,
  :_legacy_old_dti_demand_outstanding,
  :_legacy_dti_interest,
  :_legacy_old_dti_interest,
  :_legacy_lending_limit_id,
  :_legacy_old_lending_limit_id,
  :_legacy_postcode,
  :_legacy_old_postcode,
  :_legacy_lender_reference,
  :_legacy_old_lender_reference,
]

scope = DataCorrection.where('_legacy_sortcode is not null OR _legacy_old_sortcode is not null')

scope = fields.inject(scope) do |memo, field|
  memo.where("#{field} is null")
end

scope.each do |data_correction|
  data_correction.update_column(:change_type_id, ChangeType::Sortcode.id)
end
