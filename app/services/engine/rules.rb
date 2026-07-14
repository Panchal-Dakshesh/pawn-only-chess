module Engine
  # Move legality, execution, and end-of-game detection. All methods take a
  # Board and engine colors ("w" / "b"). Board-mutating methods end in !.
  module Rules
    extend self

    def opponent(color)
      color == Board::WHITE ? Board::BLACK : Board::WHITE
    end

    # White marches up the ranks, Black down.
    def direction(color)
      color == Board::WHITE ? 1 : -1
    end

    def far_rank(color)
      color == Board::WHITE ? Board::SIZE - 1 : 0
    end

    def legal_moves(board, color)
      board.pawns(color).flat_map { |from| legal_moves_from(board, from) }
    end

    def legal_moves_from(board, from)
      rank, file = from
      color = board.at(rank, file)
      return [] if color == Board::EMPTY

      next_rank = rank + direction(color)
      return [] unless next_rank.between?(0, Board::SIZE - 1)

      moves = []
      if board.empty_at?(next_rank, file)
        moves << Move.new(from: from, to: [ next_rank, file ], capture: false)
      end
      [ file - 1, file + 1 ].each do |next_file|
        next unless next_file.between?(0, Board::SIZE - 1)
        if board.at(next_rank, next_file) == opponent(color)
          moves << Move.new(from: from, to: [ next_rank, next_file ], capture: true)
        end
      end
      moves
    end

    # One step straight forward onto an empty square.
    def move!(board, from, to)
      color = pawn_at!(board, from)
      legal = to[1] == from[1] &&
              to[0] == from[0] + direction(color) &&
              board.empty_at?(*to)
      raise IllegalMoveError, illegal(from, to, "pawns move one step forward onto an empty square") unless legal

      execute(board, from, to, color, capture: false)
    end

    # One step diagonally forward onto an opponent's pawn.
    def kill!(board, from, to)
      color = pawn_at!(board, from)
      legal = (to[1] - from[1]).abs == 1 &&
              to[0] == from[0] + direction(color) &&
              board.at(*to) == opponent(color)
      raise IllegalMoveError, illegal(from, to, "pawns capture one step diagonally forward onto an opponent's pawn") unless legal

      execute(board, from, to, color, capture: true)
    end

    # Dispatches to kill! when the destination holds an enemy pawn, move! otherwise.
    def apply!(board, from, to)
      color = pawn_at!(board, from)
      if board.at(*to) == opponent(color)
        kill!(board, from, to)
      else
        move!(board, from, to)
      end
    end

    # color has won if one of its pawns reached the far rank, or the
    # opponent has no pawns left.
    def win?(board, color)
      far = far_rank(color)
      board.pawns(color).any? { |rank, _file| rank == far } ||
        board.count(opponent(color)).zero?
    end

    # Draw when the side to move has no legal move.
    def draw?(board, color_to_move)
      legal_moves(board, color_to_move).empty?
    end

    # Game status after `color` has just moved.
    def status_after(board, color)
      if win?(board, color)
        color == Board::WHITE ? "white_won" : "black_won"
      elsif draw?(board, opponent(color))
        "draw"
      else
        "in_progress"
      end
    end

    private

    def pawn_at!(board, from)
      unless to_bounds?(from) && !board.empty_at?(*from)
        raise IllegalMoveError, "no pawn on #{Board.square_name(*from)}"
      end
      board.at(*from)
    end

    def to_bounds?(sq)
      sq[0].between?(0, Board::SIZE - 1) && sq[1].between?(0, Board::SIZE - 1)
    end

    def execute(board, from, to, color, capture:)
      raise IllegalMoveError, illegal(from, to, "destination is off the board") unless to_bounds?(to)
      board.set(*from, Board::EMPTY)
      board.set(*to, color)
      Move.new(from: from, to: to, capture: capture)
    end

    def illegal(from, to, reason)
      "illegal move #{Board.square_name(*from)} to #{Board.square_name(*to)}: #{reason}"
    end
  end
end
