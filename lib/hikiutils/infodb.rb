# -*- coding: utf-8 -*-
require 'kconv'

class InfoDB
  attr_accessor :file_path, :db, :text_dir
  def initialize(file_path)
    @file_path=File.join(file_path,"info.db")
    @db = Hash.new
    file = File.read(@file_path)
    if Kconv.iseuc(file) then
      print "WARNING : info.db is euc, not supported.\n"
      print "#{@file_path}.\n"
      exit
    end
    @db = TMarshal::load(file)
  end

  def show(name)
    @db[name]
  end

  def delete(name)
    p @db.delete(name)
  end

  def update(name)
    if @db[name]==nil then
      puts "no info"
      exit
    end
    p @db[name][:last_modified] = Time.now
    self.dump
  end

  def dump
    dump_file = File.open(@file_path,'w')
    TMarshal::dump(@db,dump_file)
    dump_file.close
  end

  def show_inconsist
    @text_dir = Dir::entries(File.join(file_path,"text"))[3..-1]
    cont = ""
    @text_dir.each { |ent|
      if @db[ent]==nil then
        cont << "in text_dir but not in db:#{ent}\n"
        next
      end
      #  newdb.store(ent,db[ent])
    }

    @db.each { |ent|
      name = ent[0]
      if !(@text_dir.member? (name)) then
        cont <<  "in db but not in text_dir:#{name}\n"
      end
    }
    return cont
  end
end
