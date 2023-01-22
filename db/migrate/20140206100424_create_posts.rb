class CreatePosts < ActiveRecord::Migration[4.2]
  def change
    create_table :posts do |t|
      t.string :title
      t.text :content
      t.integer :user_id
      t.integer :problem_id

      t.timestamps
    end
  end
end
