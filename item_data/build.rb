require 'sqlite3'
require 'yaml'
require 'xmlsimple'
require 'pp'

module Calyx
 module Calyx::Item
  class ItemDefinition
    attr :id
    attr_reader :properties
  end
 end
end

# Load weight data
print "Loading weight data ... "
weight_data = File.open("weights.txt", "r").readlines.collect do |line|
  tokens = line.strip.split(" ")
  tokens[0] = tokens[0].to_i # ID to integer
  tokens[1] = tokens[1].to_f # Weight to float
  
  tokens
end

weights = Hash[*weight_data.flatten]
print "done (#{weights.size} items)\n"

# Load bonus data
print "Loading bonus data ... "
bonus_data = XmlSimple.xml_in("bonuses.xml")
bonuses = {}
bonus_names = [
  :att_stab_bonus,
  :att_slash_bonus,
  :att_crush_bonus,
  :att_magic_bonus,
  :att_ranged_bonus,
  :def_stab_bonus,
  :def_slash_bonus,
  :def_crush_bonus,
  :def_magic_bonus,
  :def_ranged_bonus,
  :strength_bonus,
  :prayer_bonus
]
bonus_str1 = bonus_names.collect {|e| "#{e} INTEGER" }.join(", ")

bonus_data['bonus'].each {|row|
  id = row['id'].first.to_i
  bon = row['bonuses'].first['int'].collect {|s| s.to_i }
  bonuses[id] = bon
}

print "done (#{bonuses.size} items)\n"

# Load price data
print "Loading price data ... "
prices = {}

f = File.open("prices.txt", "r")
fl = f.lines.to_a

fl.each {|l| 
  l = l.split(" = ")
  id = l[0].strip.to_i
  val = l[1].strip.to_i
  prices[id] = val
}

print "done (#{prices.size} items)\n"

# Load item definitions
print "Loading definitions ... "
definitions = YAML::load(File.open('item_data.txt'))
print "done (#{definitions.size} items)\n"

db = SQLite3::Database.new(':memory:')
db.execute "CREATE TABLE items (id INTEGER PRIMARY KEY, name VARCHAR(255), noted BOOL, parent INTEGER, noteable BOOL, noteID INTEGER, stackable BOOL, members BOOL, prices BOOL, basevalue INTEGER, #{bonus_str1}, weight)"

definitions.each {|d|
  i = d.id
  print "Inserting item ##{i}" + (i < definitions.size-1 ? ("\b" * (i.to_s.size + "Inserting item #".size)) : "")
  p = d.properties
  
  val = prices[i]
  
  xb = bonuses[i] || Hash.new(0)
  
  db.execute "insert into items (id, name, noted, parent, noteable, noteID, stackable, members, prices, basevalue, #{bonus_names.join(", ")}, weight) values (#{i}, \"#{p[:name]}\", #{p[:noted] ? 1 : 0}, #{p[:parent]}, #{p[:noteable] ? 1 : 0}, #{p[:noteID]}, #{p[:stackable] ? 1 : 0}, #{p[:members] ? 1 : 0}, #{p[:prices] ? 1 : 0}, #{val}, #{xb[0]}, #{xb[1]}, #{xb[2]}, #{xb[3]}, #{xb[4]}, #{xb[5]}, #{xb[6]}, #{xb[7]}, #{xb[8]}, #{xb[9]}, #{xb[10]}, #{xb[11]}, #{weights[i]})"
}

print " ... done\n"

# Write out database file
print "Dumping memory to file ... "
out = SQLite3::Database.new('items.db')
b = SQLite3::Backup.new(out, 'main', db, 'main')
b.step(-1)
b.finish

print "done\n"

=begin
db = SQLite3::Database.new('items.db', :readonly => true)
a = Time.now
result = db.execute("select * from items where id = 2607")
b = Time.now
c = b-a
puts "#{c * 1000}ms"
puts result.inspect
=end

