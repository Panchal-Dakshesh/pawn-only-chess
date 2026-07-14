class CreateMoves < ActiveRecord::Migration[8.1]
  def change
    create_table :moves do |t|
      t.string :game_id, null: false
      t.integer :number, null: false
      t.string :color, null: false
      t.string :from_sq, null: false
      t.string :to_sq, null: false
      t.boolean :capture, null: false, default: false
      t.datetime :created_at, null: false
    end
    add_index :moves, [ :game_id, :number ], unique: true
    add_foreign_key :moves, :games
  end
end
