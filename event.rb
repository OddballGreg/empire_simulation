class Event
  attr_accessor :name, :lifespan
  def initialize(name, lifespan)
    @name = name
    @lifespan = lifespan
  end

  def expired?
    !@lifespan.positive?
  end

  def nationalism?
    @name == 'Nationalism!'
  end

  def in_debt?
    @name == 'In Debt!'
  end

  def disloyal_soldiers?
    @name == 'Disloyal Soldiers!'
  end

  def tick!
    @lifespan -= 1
  end
end