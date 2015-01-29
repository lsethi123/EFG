class LoanAmendmentPresenter < SimpleDelegator
  class Change
    attr_reader :attribute, :old_attribute, :old_value, :value

    def initialize(attributes)
      @attribute = attributes.fetch(:attribute)
      @value = attributes.fetch(:value)
      @old_attribute = attributes.fetch(:old_attribute)
      @old_value = attributes.fetch(:old_value)
    end
  end

  include ActionView::Helpers::UrlHelper

  AmendmentTypes = %w(data_corrections loan_modifications).freeze

  attr_reader :loan, :amendment_id, :amendment_type, :amendment

  def self.for_loan(loan)
    loan_modifications = loan.loan_modifications.to_a
    data_corrections = loan.data_corrections.to_a
    amendments = loan_modifications.concat(data_corrections).sort_by(&:date_of_change)

    amendments.map do |amendment|
      amendment_type = amendment.class.base_class.name.tableize
      new(loan, id: amendment.id, type: amendment_type)
    end
  end

  def initialize(loan, opts = {})
    @loan = loan
    @amendment_id = opts.fetch(:id)
    @amendment_type = opts.fetch(:type)
    @amendment = get_amendment
    super(amendment)
  end

  def changes
    changeable_attribute_names.map do |old_attribute_name|
      old_attribute_name = old_attribute_name.sub(/_id$/, '')
      new_attribute_name = old_attribute_name.sub(/^old_/, '')

      old_value = amendment.public_send(old_attribute_name)
      new_value = amendment.public_send(new_attribute_name)

      if old_value.present? || new_value.present?
        Change.new(
          attribute: new_attribute_name,
          value: new_value,
          old_attribute: old_attribute_name,
          old_value: old_value
        )
      end
    end.compact
  end

  def date_link
    link_to date_of_change.to_s(:screen), amendment_path
  end

  def drawn_amount?
    amendment.respond_to?(:amount_drawn) && !!amount_drawn
  end

  def lump_sum_repayment?
    amendment.respond_to?(:lump_sum_repayment) && !!lump_sum_repayment
  end

  def type_of_amendment_link
    link_to change_type_name, amendment_path
  end

  private

  def amendment_path
    Rails.application.routes.url_helpers.loan_loan_amendment_path(loan, self, type: amendment_type)
  end

  def changeable_attribute_names
    case amendment
    when DataCorrection
      data_correction_changes.keys.map { |attr_name| "old_#{attr_name}" }
    when LoanChange
      attribute_names.select { |attribute| attribute.match(/^old_/) }
    else
      []
    end
  end

  def get_amendment
    unless AmendmentTypes.include?(amendment_type)
      raise ActiveRecord::RecordNotFound
    end

    loan.public_send(amendment_type).find(amendment_id)
  end

end
