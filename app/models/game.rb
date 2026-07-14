class Game < ApplicationRecord
  COLORS = %w[white black].freeze
  STATUSES = %w[in_progress white_won black_won draw].freeze

  has_many :moves, -> { order(:number) }, dependent: :destroy, inverse_of: :game

  validates :board, format: { with: /\A[wb.]{64}\z/ }
  validates :turn, :user_color, inclusion: { in: COLORS }
  validates :status, inclusion: { in: STATUSES }

  before_create { self.id ||= SecureRandom.uuid }

  def self.start!(user_color: "white")
    game = create!(board: Engine::Board.initial.to_s, user_color: user_color)
    game.play_system_move! unless game.user_turn?
    game
  end

  def in_progress? = status == "in_progress"
  def system_color = user_color == "white" ? "black" : "white"
  def user_turn? = in_progress? && turn == user_color

  def play_user_move!(from_sq, to_sq)
    raise Engine::IllegalMoveError, "game is already over" unless in_progress?
    raise Engine::IllegalMoveError, "it is not your turn" unless user_turn?
    apply!(Engine::Board.parse(from_sq), Engine::Board.parse(to_sq))
  end

  def play_system_move!
    return unless in_progress? && turn == system_color
    move = Engine::SystemPlayer.new.choose(engine_board, engine_color(system_color))
    apply!(move.from, move.to) if move
  end

  def restart!
    transaction do
      moves.destroy_all
      update!(board: Engine::Board.initial.to_s, turn: "white", status: "in_progress")
    end
    play_system_move! unless user_turn?
    self
  end

  def state
    current = engine_board
    {
      id: id,
      status: status,
      turn: turn,
      user_color: user_color,
      board: board,
      legal_moves: in_progress? ? Engine::Rules.legal_moves(current, engine_color(turn)).map(&:as_json) : [],
      moves: moves.map do |m|
        { number: m.number, color: m.color, from: m.from_sq, to: m.to_sq, capture: m.capture }
      end,
      captured: {
        white: Engine::Board::SIZE - current.count(Engine::Board::WHITE),
        black: Engine::Board::SIZE - current.count(Engine::Board::BLACK)
      }
    }
  end

  private

  def engine_board = Engine::Board.from_s(board)
  def engine_color(color) = color == "white" ? Engine::Board::WHITE : Engine::Board::BLACK

  def apply!(from, to)
    playing_board = engine_board
    mover = turn
    unless playing_board.at(*from) == engine_color(mover)
      raise Engine::IllegalMoveError, "no #{mover} pawn on #{Engine::Board.square_name(*from)}"
    end
    move = Engine::Rules.apply!(playing_board, from, to)
    transaction do
      self.board = playing_board.to_s
      self.status = Engine::Rules.status_after(playing_board, engine_color(mover))
      self.turn = mover == "white" ? "black" : "white" if in_progress?
      save!
      moves.create!(number: moves.count + 1, color: mover,
                    from_sq: move.from_sq, to_sq: move.to_sq, capture: move.capture)
    end
    move
  end
end
