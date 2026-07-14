class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games, id: :string do |t|
      t.string :board, null: false
      t.string :turn, null: false, default: "white"
      t.string :status, null: false, default: "in_progress"
      t.string :user_color, null: false, default: "white"
      t.timestamps
    end
  end
end
