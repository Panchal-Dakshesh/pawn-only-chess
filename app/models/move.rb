class Move < ApplicationRecord
  belongs_to :game, inverse_of: :moves

  validates :number, :color, :from_sq, :to_sq, presence: true
end
