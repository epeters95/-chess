class Piece

  # This object will not have a db table to persist itself. Too many rows.
  # How can a board be saved on the database without also saving piece objects?
  # The answer is that we will add a text column to Board representing the serialized 8x8 array.
  # Pieces will be represented with a notation illustrated in to_json

  include Util

  def self.knight_moves; [[1,2],[1,-2],[-1,2],[-1,-2],[2,1],[-2,1],[2,-1],[-2,-1]]; end
  def self.rook_moves;   [[0,1],[1,0],[0,-1],[-1,0]]; end
  def self.bishop_moves; [[1,1],[1,-1],[-1,1],[-1,-1]]; end
  def self.crown_moves;  [[1,1],[1,-1],[-1,1],[-1,-1],[0,1],[1,0],[0,-1],[-1,0]]; end

  attr_accessor :color, :position, :val
  attr_reader :char, :ranged, :played_moves, :taken

  def initialize(color, position, played_moves=[])
    @color = color
    @position = position
    @played_moves = played_moves
    @current_legal_moves = []
    @ranged = (self.is_a?(Rook) || self.is_a?(Bishop) || self.is_a?(Queen))
    @taken = false
    @char = "?"
    @val = 0
  end

  def clear_moves
    @current_legal_moves = []
  end

  def get_moves
    @current_legal_moves
  end

  def add_moves(moves)
    @current_legal_moves.concat moves
  end

  def self.generate(piece_type, color, pos)
    case piece_type
    when "pawn"
      pc = Pawn.new(color, pos)
    when "knight"
      pc = Knight.new(color, pos)
    when "bishop"
      pc = Bishop.new(color, pos)
    when "rook"
      pc = Rook.new(color, pos)
    when "queen"
      pc = Queen.new(color, pos)
    when "king"
      pc = King.new(color, pos)
    end
    pc
  end

  def deep_dup
    # TODO: determine if necessary to rewrite the mv.deep_dup action considering played_moves is generated from JSON
    return self.class.new(@color, @position, @played_moves.map{|mv| mv.deep_dup(mv.piece, mv.other_piece)})
  end

  def take
    @taken = true
    @position = nil
  end

  def set_played(move)
    @played_moves << move
    @current_legal_moves = []
  end

  def piece_directions
    # subclasses define     
    []
  end
  

  # Utilities
  def file
    @position[0]
  end

  def rank
    @position[1]
  end

  def notation
    @char
  end

  def to_s
    notation
  end

  def to_json(exclude_moves=false, options = {})
    exclude_vars = [:@char, :@val, :@letter]
    exclude_vars << [:@current_legal_moves] if exclude_moves
    vars = instance_variables.excluding exclude_vars
    merged_hash = vars.to_h do |iv|
      [iv.to_s.delete('@'), instance_variable_get(iv)]
    end.merge(
      {
        piece_directions: piece_directions,
        class_name: self.class.name
      }
    )
    JSON.generate(merged_hash, options)
  end

  def self.from_json_str(piece_str, exclude_moves=false)
    if piece_str.nil? || piece_str == "null"
      return nil
    end
    self.from_json(JSON.parse(piece_str), exclude_moves)
  end

  def self.from_json(json_obj, exclude_moves=false)
    klass = Object.const_get(json_obj["class_name"])
    init_arg_names = klass.instance_method(:initialize).parameters.map{|pm| pm[1].to_s }
    args = init_arg_names.map{|arg| json_obj[arg] }
    piece_obj = klass.new(*args)
    unless exclude_moves
      piece_obj.add_moves(json_obj["current_legal_moves"].map{|lm| Move.from_json(lm)})
    end
    piece_obj
  end
end


class Pawn < Piece
  attr_reader :letter, :char, :val
  def initialize(color, position, played_moves=[])
    super
    @letter = "p "
    @char = "\u265f "
    @val = 1
    @moved = false
  end

  def pawn_dir
    @pawn_dir ||= (@color == "white" ? 1 : -1)
  end

  def pawn_attack_dirs
    [[-1, pawn_dir], [1, pawn_dir]]
  end
  
  def pawn_moves
    mvs = [[0, 1*pawn_dir]]
    mvs << [0, 2*pawn_dir] if rank_idx(@position) == (3.5 - 2.5*pawn_dir)
    mvs
  end

  def piece_directions
    pawn_moves
  end

  def pawn_attacks
    attacks = []
    pawn_attack_dirs.each do |dir|
      new_place = [file_idx(@position) + dir[0], rank_idx(@position) + dir[1]]
      next if outside?(new_place)
      attacks << new_place
    end
    attacks
  end

end

class Bishop < Piece
  attr_reader :letter, :char, :val
  def initialize(color, position, played_moves=[])
    super
    @letter = "B "
    @char = "\u265d "
    @val = 3
  end
  def piece_directions
    Piece.bishop_moves
  end
end

class Knight < Piece
  attr_reader :letter, :char, :val
  def initialize(color, position, played_moves=[])
    super
    @letter = "N "
    @char = "\u265e "
    @val = 3
  end
  def piece_directions
    Piece.knight_moves
  end
end

class Rook < Piece
  attr_accessor :castleable
  attr_reader :letter, :char, :val
  def initialize(color, position, castleable=true, played_moves=[])
    super(color, position)
    @letter = "R "
    @char = "\u265c "
    @castleable = castleable
    @val = 5
  end

  def deep_dup
    return self.class.new(@color, @position, @castleable)
  end

  def set_castleable
    @castleable = false
  end

  def set_played(move)
    super
    @castleable = false
  end

  def piece_directions
    Piece.rook_moves
  end
end  

class Queen < Piece
  attr_reader :letter, :char, :val
  def initialize(color, position, played_moves=[])
    super
    @letter = "Q "
    @char = "\u265b "
    @val = 9
  end

  def piece_directions
    Piece.crown_moves
  end

end

class King < Piece
  attr_accessor :castleable
  attr_reader :letter, :char, :val
  def initialize(color, position, castleable=true, played_moves=[])
    super(color, position)
    @letter = "K "
    @char = "\u265a "
    @val = 77
    @castleable = castleable
  end
  def set_played(move)
    super
    @castleable = false
  end
  def set_castleable
    @castleable = false
  end
  def piece_directions
    Piece.crown_moves
  end
  def deep_dup
    return self.class.new(@color, @position, @castleable)
  end
end

