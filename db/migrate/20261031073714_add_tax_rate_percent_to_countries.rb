class AddTaxRatePercentToCountries < ActiveRecord::Migration[8.1]
  # Existing countries start at 0% so the column can be NOT NULL; the default
  # is then removed so every new country must be given a rate.
  def change
    add_column :countries, :tax_rate_percent, :decimal, precision: 5, scale: 2, null: false, default: 0
    change_column_default :countries, :tax_rate_percent, from: 0, to: nil
    add_check_constraint :countries, "tax_rate_percent BETWEEN 0 AND 100", name: "countries_tax_rate_range"
  end
end
