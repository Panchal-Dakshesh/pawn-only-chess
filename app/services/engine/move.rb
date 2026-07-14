module Engine
  Move = Struct.new(:from, :to, :capture, keyword_init: true) do
    def from_sq
      Board.square_name(*from)
    end

    def to_sq
      Board.square_name(*to)
    end

    def as_json(*)
      { "from" => from_sq, "to" => to_sq, "capture" => !!capture }
    end
  end
end
