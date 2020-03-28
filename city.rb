class City
  attr_accessor :name, :owner, :unity, :literacy, :population, :manpower

  def initialize(nation)
    @owner = nation
    @name = Faker::Nation.capital_city
    @unity = rand(0..100)
    @literacy = rand(0..100)
    @population = rand(1000..5000)
    recalculate_manpower
    puts "\t - The city of #{name.blue} has been founded by the #{owner.nationality.blue}"
  end

  def prosper!
    modify_stat(:unity, rand(1..3))
    modify_stat(:literacy, rand(1..3))
    @population += rand(100..1000)
  end
  
  def claim!(victor)
  	@owner = victor
  	@owner.cities << self
    self
  end

  def recalculate_manpower
    @manpower = (@population * owner.recruitable_manpower).to_i
  end

  def modify_stat(stat, value)
    eval("@#{stat} += #{value}")
    eval("@#{stat} = 0") if send(stat).negative?
    eval("@#{stat} = 100") if send(stat) > 100
  end

  def kill_population(casualties)
    @population -= casualties
    if @population.negative?
      @population = 0 
      modify_stat(:literacy, -@literacy)
    else
      modify_stat(:literacy, -((@population - casualties) / @population))
    end
  end

  def destroyed?
    !@population.positive?
  end
end