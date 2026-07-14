module Engine
  # 8x8 pawn board. Ranks and files are 0-indexed internally: rank 0 is
  # chess rank 1 (White's home side), file 0 is the a-file. Serialized as a
  # 64-character string of "w" / "b" / ".", rank 1 first.
  class Board
    SIZE = 8
    EMPTY = "."
    WHITE = "w"
    BLACK = "b"
    FILES = ("a".."h").to_a.freeze

    def self.initial
      from_s(WHITE * SIZE + EMPTY * SIZE * 6 + BLACK * SIZE)
    end

    def self.blank
      from_s(EMPTY * SIZE * SIZE)
    end

    def self.from_s(str)
      unless str.is_a?(String) && str.match?(/\A[wb.]{64}\z/)
        raise ArgumentError, "board must be 64 chars of w/b/., got #{str.inspect}"
      end
      new(str.dup)
    end

    # "e2" -> [1, 4]
    def self.parse(square)
      m = /\A([a-h])([1-8])\z/.match(square.to_s.strip.downcase)
      raise IllegalMoveError, "invalid square #{square.inspect}" unless m
      [ m[2].to_i - 1, FILES.index(m[1]) ]
    end

    # [1, 4] -> "e2"
    def self.square_name(rank, file)
      FILES[file] + (rank + 1).to_s
    end

    def initialize(squares)
      @squares = squares
    end

    def at(rank, file)
      @squares[rank * SIZE + file]
    end

    def empty_at?(rank, file)
      at(rank, file) == EMPTY
    end

    def set(rank, file, piece)
      @squares[rank * SIZE + file] = piece
    end

    def pawns(color)
      out = []
      @squares.each_char.with_index do |ch, i|
        out << [ i / SIZE, i % SIZE ] if ch == color
      end
      out
    end

    def count(color)
      @squares.count(color)
    end

    def to_s
      @squares.dup
    end

    def initialize_copy(source)
      @squares = source.to_s
    end

    def inspect
      rows = (SIZE - 1).downto(0).map do |r|
        "#{r + 1} #{(0...SIZE).map { |f| at(r, f) }.join(' ')}"
      end
      (rows + [ "  #{FILES.join(' ')}" ]).join("\n")
    end
  end
end
