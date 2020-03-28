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
    @manpower = (@population * owner.recruitable_manpower.to_f).to_i
  end

  def modify_stat(stat, value)
    case stat
    when :unity
      @unity += value
      @unity = 0 if send(stat).negative?
      @unity = 100 if send(stat) > 100
    when :literacy
      @literacy += value
      @literacy = 0 if send(stat).negative?
      @literacy = 100 if send(stat) > 100
    when :population
      @population += value
      @population = 0 if send(stat).negative?
      @population = 100 if send(stat) > 100
    when :manpower
      @manpower += value
      @manpower = 0 if send(stat).negative?
      @manpower = 100 if send(stat) > 100
    else
      puts 'Unexpected stat'
    end
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