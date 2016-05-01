class Player
  attr_reader :name, :alive
  attr_accessor :role

  def initialize(name)
    @name = name
    @role = nil
    @alive = true
  end

  def to_s
    @name
  end

  def kill
    @alive = false
  end

  def is_mafia?
    @role == :mafia
  end
end
