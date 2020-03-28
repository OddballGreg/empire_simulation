require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'colorize'
  gem 'faker'
  gem 'pry'
end

require_relative 'city'
require_relative 'nation'
require_relative 'event'

def outside_truce_period?
  ($date >= $start_date + TRUCE_PERIOD)
end

$start_date = Date.today
$date = $start_date

$nation_count = 0
$historical_nation_count = 0

TIME_LIMIT = 200 #days
NATION_LIMIT = 100
TRUCE_PERIOD = 20 #days

def puts(string=nil)
  super("(#{$nation_count.to_s.green})||#{$date} => #{string}")
end

def within_time_limit?
  $date <= ($start_date + TIME_LIMIT)
end

def may_create_new_nation?
  rand(0..100) < (100 - $nation_count) && $historical_nation_count <= NATION_LIMIT
end

def spawn_nations
  if may_create_new_nation?
    new_nation = Nation.new
    $nations[new_nation.id] = new_nation
    spawn_nations
  end
end

Signal.trap("TERM") do
  puts "Terminating..."
  shutdown()
end

$nations = {}
$new_nations = {}

def simulate
  while ($nation_count > 1 or !outside_truce_period?) and within_time_limit? do
    $date += 1
    puts " --- A New Day --- "
    puts "Number of nations that exist: #{$nation_count}"

    spawn_nations

    $nations.each do |_nation_id, nation|
      nation.simulate
    end
    # sleep(0.5)
  end

  3.times do 
    puts
  end
  puts "--- Game Over ---"
  puts "Number of nations that exist: #{$nation_count}"

  $nations.sort{|a, b| a[1].cities.count <=> b[1].cities.count }.each do |_nation_id, nation|
    nation.output_stats
  end
end

simulate
