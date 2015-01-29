class MonthsInput < SimpleForm::Inputs::StringInput
  def input
    template.content_tag(:div, class: 'input-append') do
      add_on = %Q{<span class="add-on">months</span>}.html_safe
      @builder.text_field(attribute_name, default_options.merge(input_html_options)) + add_on
    end
  end

  private

  def default_options
    { maxlength: 3 }
  end
end
