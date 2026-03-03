class AddMissingIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :expenses, :recurring_source_id
    add_index :investments, [ :ticker, :investment_type ]
  end
end
