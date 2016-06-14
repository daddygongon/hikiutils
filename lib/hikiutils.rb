# -*- coding: utf-8 -*-
require 'kconv'
require "hikiutils/version"
require "hikiutils/tmarshal"
require "hikiutils/infodb"
require 'systemu'
require 'optparse'
require 'fileutils'
require 'yaml'
require 'pp'

module HikiUtils
  DATA_FILE=File.join(ENV['HOME'],'.hikirc')
  attr_accessor :src, :target, :data_name, :l_dir

  class Command
    def self.run(argv=[])
      print "hiki says 'Hello world'.\n"
      new(argv).execute
    end

    def initialize(argv=[])
      @argv = argv
      @data_name=['nick_name','local_dir','local_uri','global_dir','global_uri']
      data_path = File.join(ENV['HOME'], '.hikirc')
      DataFiles.prepare(data_path)
      read_sources
    end

    def execute
      @argv << '--help' if @argv.size==0
      command_parser = OptionParser.new do |opt|
        opt.on('-v', '--version','show program Version.') { |v|
          opt.version = HikiUtils::VERSION
          puts opt.ver
        }
        opt.on('-s', '--show','show sources') {show_sources}
        opt.on('-a', '--add','add sources info') {add_sources }
        opt.on('-t', '--target VAL','set target id') {|val| set_target(val) }
        opt.on('-e', '--edit FILE','open file') {|file| edit_file(file) }
        opt.on('-l', '--list [FILE]','list files') {|file| list_files(file) }
        opt.on('-u', '--update FILE','update file') {|file| update_file(file) }
        opt.on('-r', '--rsync','rsync files') {rsync_files}
        opt.on('-d', '--database FILE','read database file') {|file| db_file(file)}
        opt.on('-c', '--checkdb','check database file') {check_db}
        opt.on('--remove FILE','remove file') {|file| remove_file(file)}
        opt.on('--move FILES','move file1,file2',Array) {|files| move_file(files)}
        opt.on('--euc FILE','translate file to euc') {|file| euc_file(file) }
      end
      begin
        command_parser.parse!(@argv)
      rescue=> eval
        p eval
      end
      dump_sources
      exit
    end

    def euc_file(file)
      p file_path = File.join(@l_dir,'text',file)
      cont = File.readlines(file_path)

      cont.each{|line| puts line.toeuc }
    end

    def move_file(files)
      begin
        p file1_path = File.join(@l_dir,'text',files[0])
        p file2_path = File.join(@l_dir,'text',files[1])
      rescue => evar
        puts evar.to_s
        puts "error on move_files, check the input format, especially comma separation."
        exit
      end
      return if file1_path==file2_path
      if File.exist?(file2_path) then
        print ("moving target #{files[1]} exists.\n")
        print ("first remove#{files[1]}.\n")
        return
      else
        File.rename(file1_path,file2_path)
      end

      info=InfoDB.new(@l_dir)

      db = info.db

      pp file0=db[files[0]]
      db.delete(files[0])
      db[files[1]]=file0
      db[files[1]][:title]=files[1] if db[files[1]][:title]==files[0]
      pp db[files[1]]

      db.each{|ele|
        ref = ele[1][:references]
        if ref.include?(files[0]) then
          p link_file=ele[0]
          link_path = File.join(@l_dir,'text',link_file)

          cont = File.read(link_path)
          if Kconv.iseuc(cont) then
            print "euc\n"
            utf8_cont=cont.toutf8
            utf8_cont.gsub!(/#{files[0]}/,"#{files[1]}")
            cont = utf8_cont.toeuc
          else
            cont.gsub!(/#{files[0]}/,"#{files[1]}")
          end

          File.write(link_path,cont)

          ref.delete(files[0])
          ref << files[1]

          p cache_path = File.join(@l_dir,'cache/parser',link_file)
          begin
            File.delete(cache_path)
          rescue => evar
            puts evar.to_s
          end
        end
      }

      info.dump
    end

    def remove_file(file_name)
      p text_path = File.join(@l_dir,'text',file_name)
      p attach_path = File.join(@l_dir,'cache/attach',file_name)
      begin
        File.delete(text_path)
      rescue => evar
        puts evar.to_s
      end
      begin
        Dir.rmdir(attach_path)
      rescue => evar
        puts evar.to_s
      end

      info=InfoDB.new(@l_dir)
      p "delete "
      del_file=info.delete(file_name)
      info.show_link(file_name)
      info.dump
    end

    def check_db
      result= InfoDB.new(@l_dir).show_inconsist
      print (result=='') ? "db agrees with text dir.\n" : result
    end

    def db_file(file_name)
      info=InfoDB.new(@l_dir)
      p info.show(file_name)
    end

    def rsync_files
      p local = @l_dir
      p global = @src[:srcs][@target][:global_dir]
#"/Users/bob/Sites/nishitani0/Internal/data"
#"bob@dmz0:/Users/bob/nishitani0/Internal/data"
#      p command="rsync -auvz -e ssh #{local}/ #{global}"
      p command="rsync -auvz -e ssh #{local}/ #{global}"
#  system 'rsync -auvz -e ssh ~/Sites/nishitani0 bob@nishitani0.kwansei.ac.jp:Sites/'
      system command
    end

    def update_file(file0)
      file = (file0==nil) ? 'FrontPage' : file0
      #rm cache file
      t_file=File.join(@l_dir,'cache/parser',file)
      p command="rm #{t_file}"
      system command

      #update info file
      info=InfoDB.new(@l_dir)
      info.update(file0)

      #open file on browser
#      l_path = @src[:srcs][@target][:local_uri]
#      l_file=l_path+"/?"+file
      p command="open -a Firefox \'http://localhost:9292/?c=edit;p=#{file}\'"
      system command
    end

    def list_files(file)
      file ='' if file==nil
      t_file=File.join(@l_dir,'text')
      print "target_dir : "+t_file+"\n"
      print `cd #{t_file} ; ls -lt #{file}*`
    end

    def edit_file(file)
      t_file=File.join(@l_dir,'text',file)
      if !File.exist?(t_file) then
        file=File.open(t_file,'w')
        file.close
        File.chmod(0777,t_file)
      end
      p command="open -a mi #{t_file}"
      system command
    end

    def dump_sources
      file = File.open(DATA_FILE,'w')
      YAML.dump(@src, file)
      file.close
    end

    def set_target(val)
      @src[:target] = val.to_i
      show_sources
    end

    def show_sources()
      printf("target_no:%i\n",@src[:target])
      printf("editor_command:%s\n",@src[:editor_command])
      header = display_format('id','name','local directory','global uri')

      puts header
      puts '-' * header.size

      @src[:srcs].each_with_index{|src,i|
        target = i==@src[:target] ? '*':' '
        id = target+i.to_s
        name=src[:nick_name]
        local=src[:local_dir]
        global=src[:global_uri]
        puts display_format(id,name,local,global)
      }

    end

    def display_format(id, name, local, global)
      name_length  = 5-full_width_count(name)
      local_length = 45-full_width_count(local)
      [id.to_s.rjust(3), name.ljust(name_length),local.ljust(local_length), global.center(10)].join(' | ')
    end

    def full_width_count(string)
      string.each_char.select{|char| !(/[ -~｡-ﾟ]/.match(char))}.count
    end

    def add_sources
      cont = {}
      @data_name.each{|name|
        printf("%s ? ", name)
        tmp = gets.chomp
        cont[name.to_sym] = tmp
      }
      @src[:srcs] << cont
      show_sources
    end

    def read_sources
      file = File.open(DATA_FILE,'r')
      @src = YAML.load(file.read)
      file.close
      @target = @src[:target]
      @l_dir=@src[:srcs][@target][:local_dir]
    end
  end
end

module DataFiles
  def self.prepare(data_path)
    create_file_if_not_exists(data_path)
  end

  def self.create_file_if_not_exists(data_path)
    return if File::exists?(data_path)
    create_data_file(data_path)
  end

  def self.create_data_file(data_path)
    print "make #{data_path}\n"
    init_data_file(data_path)
  end

  # initialize source file by dummy data
  def self.init_data_file(data_path)
    @src = {:target => 0, :editor_command => 'open -a mi',
      :srcs=>[{:nick_name => 'hoge', :local_dir => 'hogehoge', :local_uri => 'http://localhost/~hoge',
                :global_dir => 'hoge@global_host:/hoge', :global_uri => 'http://hoge'}]}
    file = File.open(data_path,'w')
    YAML.dump(@src,file)
    file.close
  end
  private_class_method :create_file_if_not_exists, :create_data_file, :init_data_file
end


