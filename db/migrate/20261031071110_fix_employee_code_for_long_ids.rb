class FixEmployeeCodeForLongIds < ActiveRecord::Migration[8.1]
  # lpad cuts text longer than its width, so ids from 100,000 got duplicate
  # codes. Pad to at least 5 digits instead, and back uniqueness with an index.
  # A generated column's expression can't be altered, so it is recreated.
  def up
    remove_column :employees, :code
    add_column :employees, :code, :virtual, type: :string,
      as: "'EMP-' || lpad(id::text, GREATEST(5, length(id::text)), '0')", stored: true
    add_index :employees, :code, unique: true
  end

  def down
    remove_index :employees, :code
    remove_column :employees, :code
    add_column :employees, :code, :virtual, type: :string, as: "'EMP-' || lpad(id::text, 5, '0')", stored: true
  end
end
