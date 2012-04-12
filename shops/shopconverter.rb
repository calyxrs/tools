#!/usr/bin/env ruby
require 'yaml'

file = File.open("shops.txt", "r")
lines = file.lines.to_a
lines = lines.find_all {|s| s.start_with?("shop") }
lines = lines.collect {|s| 
  s = s.strip
  s = s.gsub("_", " ")
  s = s.gsub("shop\s=\s", "")
}
file.close

data = []

lines.each {|line|
  tokens = line.split("\s")
  
  id = tokens.shift.to_i
  
  name = ""
  stop = -1
  
  tokens.each_with_index {|str, i|
    begin
      Integer(str)
      stop = i if stop == -1
    rescue
      name << str
      name << " "
    end
  }
  
  name = name.strip
  tokens = tokens[stop..-1]
  smod = tokens.shift.to_i
  bmod = tokens.shift.to_i
  tokens = tokens.collect {|e| e.to_i }
  
  items = []
  
  tokens.each_slice(2) {|id, amount|
    items << {"id" => id, "amount" => amount}
  }
  
  data << {
    "id" => id,
    "name" => name,
    "customstock" => smod == 1,   # whether or not we can sell items that aren't in stock already (general store vs. specialty shop)
    "generalstore" => bmod == 1,  # general store: if true prices are higher
    "items" => items
  }
}

output = File.new('shops.yaml', 'w')
output.puts YAML.dump(data)
output.close

