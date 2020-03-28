class Nation
  @@id_count = -1
  attr_accessor :id, :nationality, :literacy, :war_readiness, :ducats, :unity, :cities, :events, :population, :manpower, :recruitable_manpower_base, :recruitable_manpower

  def initialize
    @id = newest_id
    @nationality = Faker::Nation.unique.nationality
    @player = spawn_player?
    $nation_count += 1
    $historical_nation_count += 1

    @events = []

    @recruitable_manpower_base = rand(0.10..033)
    @ducats = rand(0..100_000)

    puts "The #{nationality} form a nation.".blue

    recalculate_recruitable_manpower

    @cities = [City.new(self)]
    rand(0..2).times { @cities << City.new(self) } #extra city chance

    recalculate_unity_ratio
    recalculate_literacy_ratio
    recalculate_population
    recalculate_manpower
    recalculate_war_readiness

    output_stats
  end

  def effective_manpower
    if recruitable_manpower.positive? && manpower.positive?
      (manpower / recruitable_manpower).to_i
    else
      0
    end
  end

  def output_stats
    puts "Nation: #{nationality.green}"
    puts "\t - Recruitable Manpower: #{recruitable_manpower.round(2).to_s.green}%"
    puts "\t - Manpower: #{manpower.to_s.green}"
	  puts "\t - Effective Manpower: #{effective_manpower.to_s.green}"
    puts "\t - Literacy: #{literacy.to_s.green}"
    puts "\t - Population: #{population.to_s.green}"
    puts "\t - War Readiness: #{war_readiness.to_s.green}"
    puts "\t - Unity: #{unity.to_s.green}"
    puts "\t - Ducats: #{ducats.to_s.green}"
    puts "\t - Cities (#{cities.size.to_s.green}):"
    cities.map(&:name).each_slice(5) do |batch|
      puts "\t - #{batch}"
    end
    puts "\t - Events (#{events.size.to_s.yellow}):"
    events.map(&:name).each_slice(5) do |batch|
      puts "\t - #{batch}"
    end
  end

  def lose_city
    lost_city = @cities.pop
  	lost_city.owner = nil
  	lost_city
  end
  
  def recalculate_recruitable_manpower
    @recruitable_manpower = recruitable_manpower_base + (events.select(&:nationalism?).size * 0.25) - (events.select(&:disloyal_soldiers?).size * 0.5)
  end

  def recalculate_manpower
    @manpower = @cities.map(&:manpower).sum
  end

  def recalculate_population
    @population = @cities.map(&:population).sum
  end

  def recalculate_literacy_ratio
    @literacy = (@cities.map(&:literacy).sum / @cities.size)
  end

  def recalculate_unity_ratio
    @unity = (@cities.map(&:unity).sum / @cities.size)
  end

  def war_readiness_ducat_threshold
    (@ducats.abs / 10000).to_i
  end

  def ducat_war_readiness
    ((ducats / 1000) * war_readiness_ducat_threshold).to_i
  end

  def event_war_readiness
    debt_events = @events.select{ |event| event.name == 'In Debt!'}
    -10 * debt_events.size
  end

  def manpower_war_readiness
    (manpower / 1000).to_i
  end

  def recalculate_war_readiness
    @war_readiness = [(literacy + unity + ducat_war_readiness + event_war_readiness + rand(0..100) + manpower_war_readiness) / 6, 100].min
    @war_readiness = 0 if @war_readiness.negative?
  end

  def spend_ducats!(ammount)
    @ducats -= ammount
    if @ducats.negative?
      @events << Event.new("In Debt!", 10)
    end
  end

  def earn_ducats!(ammount)
    @ducats += ammount
    if @ducats.positive?
      @events = @events.reject(&:in_debt?)
    end
  end

  def spend_manpower!(ammount)
    @manpower -= ammount
    if @manpower.negative?
      @events << Event.new("Manpower Shortage!", 10)
    end
  end

  def go_to_war!
    spend_ducats!(rand(1000..10000))
    victim = $nations[$nations.keys.sample]
	  return if victim == self #Civil war roll?
    puts "The #{nationality.red} go to war with the unfortunate #{victim.nationality.yellow}!"
    if war_readiness > victim.war_readiness
      annexed_city = victim.lose_city
      annexed_city.modify_stat(:unity, -(rand(10..50)))
      casualties = rand(100..1000)
      annexed_city.kill_population(casualties)
      if annexed_city.destroyed?
        plunder = victim.ducats / (casualties.to_f / victim.population)
        victim.spend_ducats!(plunder)
        earn_ducats!(plunder)
        puts "The evil #{nationality.red} slaughter the inhabitants of #{annexed_city.name}, leaving none living and plundering #{plunder.to_s.blue}."
      else
        recalculate_unity_ratio
    		annexed_city.claim!(self)
        recalculate_unity_ratio
        recalculate_war_readiness
        recalculate_population
        puts "The #{nationality.red} now possess the city of #{annexed_city.name}."
        puts "City Count: #{cities.size.to_s.green}"
        puts "War Readiness: #{war_readiness.to_s.green}"
      end

      unless victim.cities.size.positive?
        puts "The #{victim.nationality} are no more.".red
        if victim.player?
          puts 'It seems your nation has come to an end...'.red.underline
          puts 'Press enter to continue on to the end of history...'.red.blink
          gets
        end
        $nations.delete(victim.id)
        $nation_count -= 1
      end

      go_to_war!
    else
      puts "The #{victim.nationality.yellow} succesfully defend themselves against the cruel #{nationality.red}!"
      # YOOOOOOO This doesn't work anymore. need event
      war_readiness_loss = rand(5..10)
      modify_stat(:war_readiness, -war_readiness_loss)
      puts "#{nationality.red} War Readiness Lost: #{war_readiness_loss.to_s.red}"
      puts "#{nationality.red} War Readiness: #{war_readiness.to_s.green}"
    end
  end

  def modify_stat(stat, value)
    eval("@#{stat} += #{value}")
    eval("@#{stat} = 0") if send(stat).negative?
    eval("@#{stat} = 100") if send(stat) > 100
  end

  def prosper!
    puts "The #{nationality} prosper!".green
    recalculate_literacy_ratio
    @cities.each(&:prosper!)
    recalculate_unity_ratio
    # @ducats += (population * (0.1000 + (literacy * 0.10)))
    @ducats += rand(1000..2000)
    recalculate_war_readiness
    output_stats
  end

  def spawn_player?
    $nation_count.zero? && ARGV.any?{|arg| arg == '--player'}
  end

  def player?
    @player
  end

  def ready_to_go_to_war?
    (war_readiness + rand(0..100)) > 150
  end

  def good_times?
    (literacy + unity + rand(0..100)) > 150
  end

  def nationalism?
    rand(0..75) && unity > 150
  end

  def debt_comes_due?
    @events.map(&:in_debt?).size + rand(0..10) > 11
  end

  def economy_crumbles!
    cities.each do |city|
      city.modify_stat(:unity, -((city.population / population) + rand(0..10)) )
      city.kill_population(ducats.abs)
    end
    @events << Event.new('Disloyal Soldiers!', 30)
    spend_manpower!(ducats.abs / 5)
    recalculate_unity_ratio
  end

  def simulate
    if @player
      player_turn
    else
      if ready_to_go_to_war? && outside_truce_period?
        go_to_war!
      elsif debt_comes_due?
        economy_crumbles!
      elsif good_times?
        prosper!
      elsif nationalism?
        @events << Event.new('Nationalism!', 20)
      end

      @events.map(&:tick!)
      @events = @events.reject(&:expired?)
    end
  end

  private

  def player_turn
    turn = true

    puts 'What would you like to do?'.blue.blink
    puts 'status: See Nation Status'
    puts 'end turn, e: Proceed to next day'
    while turn
      input = gets.chomp

      case input
      when 'status'
        puts Self.inspect
      when 'end turn', 'e', ''
        turn = false
      else
        puts 'Unexpected command. Please try again?'
      end
    end
  end

  def newest_id
    @@id_count += 1
  end
end