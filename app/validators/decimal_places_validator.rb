# Rejects values with more decimal places than allowed. Decimal columns round
# on assignment, so this checks the value as it was entered: HR gets an error
# instead of a silently rounded number.
#
#   validates :amount, decimal_places: 2
class DecimalPlacesValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, _value)
    places = options[:with]
    entered = BigDecimal(record.read_attribute_before_type_cast(attribute).to_s, exception: false)
    return if entered.nil? || entered == entered.round(places)

    record.errors.add(attribute, "can have at most #{places} decimal places")
  end
end
