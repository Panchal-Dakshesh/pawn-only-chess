# pawn_ai.rb — self-contained move chooser for pawn-only chess. No dependencies.
#
#   require_relative "pawn_ai"
#   PawnAI.best_move(board, color)   #=> {from: "e5", to: "d4", capture: true}, or nil if stuck
#
# board: 64-char string of 'w' / 'b' / '.', rank 1 first (index = rank*8 + file)
# color: "w" or "b" (the side to move)
# depth: search depth — 1 = greedy/easy, 6 = strong (default)
module PawnAI
  WIN = 1_000_000

  module_function

  def best_move(board, color, depth: 6)
    best = nil
    alpha = -Float::INFINITY
    ordered(legal_moves(board, color)).each do |from, to|
      child = play(board, from, to)
      score = win?(child, color) ? WIN + depth
                                 : -negamax(child, flip(color), depth - 1, -Float::INFINITY, -alpha)
      (alpha = score; best = [ from, to ]) if score > alpha
    end
    return nil unless best
    { from: sq(best[0]), to: sq(best[1]), capture: board[best[1]] == flip(color) }
  end

  # --- search ---------------------------------------------------------------

  def negamax(board, color, depth, alpha, beta)
    return -(WIN + depth) if win?(board, flip(color)) # opponent's last move won; nearer wins score higher
    moves = legal_moves(board, color)
    return 0 if moves.empty?                          # side to move is stuck: draw
    return evaluate(board, color) if depth <= 0

    best = -Float::INFINITY
    ordered(moves).each do |from, to|
      score = -negamax(play(board, from, to), flip(color), depth - 1, -beta, -alpha)
      best = score if score > best
      alpha = score if score > alpha
      break if alpha >= beta
    end
    best
  end

  # --- rules ----------------------------------------------------------------

  def flip(color) = color == "w" ? "b" : "w"

  def legal_moves(board, color)
    dir = color == "w" ? 8 : -8
    moves = []
    board.each_char.with_index do |ch, i|
      next unless ch == color
      f = i + dir
      next unless f.between?(0, 63)
      moves << [ i, f ] if board[f] == "."
      moves << [ i, f - 1 ] if i % 8 > 0 && board[f - 1] == flip(color)
      moves << [ i, f + 1 ] if i % 8 < 7 && board[f + 1] == flip(color)
    end
    moves
  end

  def play(board, from, to)
    child = board.dup
    child[to] = child[from]
    child[from] = "."
    child
  end

  def win?(board, color)
    far = color == "w" ? (56..63) : (0..7)
    board[far].include?(color) || !board.include?(flip(color))
  end

  # captures first: alpha-beta prunes far harder on good-move-first ordering
  def ordered(moves) = moves.sort_by { |_, to| to == "." ? 1 : 0 }

  # --- evaluation -----------------------------------------------------------
  # Key pawn-only insight: with no kings, a "runner" (no pawn ahead on its
  # file, no enemy ahead on adjacent files) can never be stopped — so mutual
  # runners are a pure race, and the side to move wins ties.

  def evaluate(board, color)
    side(board, color) - side(board, flip(color)) + race(board, color)
  end

  def side(board, color)
    total = 0
    board.each_char.with_index do |ch, i|
      next unless ch == color
      advance = color == "w" ? i / 8 : 7 - i / 8
      total += 100 + 5 * advance
      total += 40 + 10 * advance if runner?(board, color, i)
    end
    total
  end

  def race(board, color)
    mine = runner_distance(board, color)
    theirs = runner_distance(board, flip(color))
    return WIN / 2 - 1_000 * mine if mine && (theirs.nil? || mine <= theirs)
    return -(WIN / 2 - 1_000 * theirs) if theirs
    0
  end

  def runner_distance(board, color)
    (0..63).select { |i| board[i] == color && runner?(board, color, i) }
           .map { |i| color == "w" ? 7 - i / 8 : i / 8 }
           .min
  end

  def runner?(board, color, i)
    dir = color == "w" ? 8 : -8
    enemy = flip(color)
    j = i + dir
    while j.between?(0, 63)
      return false if board[j] != "."
      return false if j % 8 > 0 && board[j - 1] == enemy
      return false if j % 8 < 7 && board[j + 1] == enemy
      j += dir
    end
    true
  end

  def sq(i) = ("a".ord + i % 8).chr + (i / 8 + 1).to_s
end

if __FILE__ == $PROGRAM_NAME
  board = "w" * 8 + "." * 48 + "b" * 8
  p PawnAI.best_move(board, ARGV[0] || "w")
end
