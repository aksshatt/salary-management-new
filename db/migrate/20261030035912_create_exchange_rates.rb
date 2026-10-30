class CreateExchangeRates < ActiveRecord::Migration[8.1]
  def change
    create_table :exchange_rates do |t|
      t.string :currency_code, null: false
      t.decimal :units_per_usd, precision: 18, scale: 6, null: false

      t.timestamps

      t.check_constraint "units_per_usd > 0", name: "exchange_rates_positive"
    end
    add_index :exchange_rates, :currency_code, unique: true
  end
end
