class RenewTestdata < ActiveRecord::Migration[4.2]
  def change
    drop_table :testdata
    create_table :testdata do |t|
      t.integer :problem_id
      t.string :test_input
      t.string :test_output

      t.timestamps
    end
  end
end
