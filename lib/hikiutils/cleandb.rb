class CleanDB
  attr_accessor :file_path, :db, :text_dir
  def initialize(file_path)
    @db = Hash.new
    file = File.read(File.join(file_path,"info.db"))
    @db = TMarshal::load(file)
    @text_dir = Dir::entries(File.join(file_path,"text"))[3..-1]
  end

  def show_inconsist
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
