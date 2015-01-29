module BasicDataCorrectable
  extend ActiveSupport::Concern

  module ClassMethods
    attr_reader :attribute_name, :change_type

    def data_corrects(attribute_name, opts = {})
      @attribute_name = attribute_name
      @change_type = "ChangeType::#{attribute_name.to_s.classify}".constantize

      attr_accessor attribute_name
      attr_accessible attribute_name

      unless opts[:skip_validation]
        validates attribute_name, presence: true
      end
    end
  end

  private

  def change_type
    self.class.change_type
  end

  def update_loan
    loan.public_send("#{attribute_name}=", attribute_value)
  end

  def attribute_name
    self.class.attribute_name
  end

  def attribute_value
    public_send(attribute_name)
  end

end
