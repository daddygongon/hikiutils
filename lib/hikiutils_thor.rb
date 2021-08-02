# -*- coding: utf-8 -*-
require "thor"
require "kconv"
require "hikidoc"
require "erb"
require "hikiutils/version"
require "hikiutils/tmarshal"
require "hikiutils/infodb"
require "systemu"
require "fileutils"
require "yaml"
require "pp"

module Hikithor
  DATA_FILE = File.join(ENV["HOME"], ".hikirc")
  attr_accessor :src, :target, :editor_command, :browser, :data_name, :l_dir

  class CLI < Thor
    HTML_TEMPLATE = <<EOS
<!DOCTYPE html
    PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<html>
<head>
  <meta http-equiv="Content-Language" content="ja">
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
  <title><%= title %></title>
</head>
<body>
  <%= body %>
</body>
</html>
EOS

    def initialize(*args)
      super
      @data_name = ["nick_name", "local_dir", "local_uri", "global_dir", "global_uri"]
      data_path = File.join(ENV["HOME"], ".hikirc")
      DataFiles.prepare(data_path)

      File.open(DATA_FILE, "r") { |file| @src = YAML.load(file.read) }

      @target = @src[:target]
      @l_dir = @src[:srcs][@target][:local_dir]
      browser = @src[:browser]
      @browser = (browser == nil) ? "firefox" : browser
      editor_command = @src[:editor_command]
      @editor_command = (editor_command == nil) ? "open -a mi" : editor_command
      printf("target_no:%i\n", @target)
      printf("editor_command:%s\n", @editor_command)
    end

    desc "pwd", "list nick_names and print working dir"
    #    map "--show" => "show"
    def pwd
      @i_size, @n_size, @l_size, @g_size = 3, 5, 30, 15 #i,g_size are fixed
      n_l, l_l = 0, 0
      @src[:srcs].each_with_index { |src, i|
        n_l = (n_l = src[:nick_name].length) > @n_size ? n_l : @n_size
        l_l = (l_l = src[:local_dir].length) > @l_size ? l_l : @l_size
      }
      @n_size, @l_size = n_l, l_l
      header = display_format("id", "name", "local directory", "global uri", @i_size, @n_size, @l_size, @g_size)

      puts header
      puts "-" * header.size

      @src[:srcs].each_with_index { |src, i|
        target = i == @src[:target] ? "*" : " "
        id = target + i.to_s
        name = src[:nick_name]
        local = src[:local_dir]
        global = src[:global_uri]
        puts display_format(id, name, local, global, @i_size, @n_size, @l_size, @g_size)
      }
    end

    desc "-v", "show program version"
    #    map "--version" => "version"
    map "-v" => "version"

    def version
      puts HikiUtils::VERSION
    end

    desc "add", "add sources info"
    #    map "--add" => "add"
    #    option :add
    def add
      cont = {}
      @data_name.each { |name|
        printf("%s ? ", name)
        tmp = STDIN.gets.chomp
        cont[name.to_sym] = tmp
      }
      @src[:srcs] << cont
      show
    end

    desc "cd VAL", "set target id"
    #    map "--target" => "target"
    def cd(val)
      @src[:target] = val.to_i
      pwd
      dump_sources
    end

    desc "open FILE", "open file for editing"
    #    map "--edit" => "edit"
    def open(file)
      t_file = File.join(@l_dir, "text", file)
      unless File.exist?(t_file)
        file = File.open(t_file, "w")
        file.close
        File.chmod(0777, t_file)
      end
      p command = "#{@editor_command} #{t_file}"
      system command
    end

    desc "ls [FILE]", "list files"
    #    map "--list" => "list"
    def ls(file)
      file = "" if file == nil
      t_file = File.join(@l_dir, "text")
      print "target_dir : " + t_file + "\n"
      print `cd #{t_file} ; ls -lt #{file}*`
    end

    desc "touch FILE", "update FILE"
    #    map "--update" => "update"
    def touch(file0)
      file = (file0 == nil) ? "FrontPage" : file0
      t_file = File.join(@l_dir, "cache/parser", file)
      begin
        FileUtils.rm(t_file, :verbose => true)
        info = InfoDB.new(@l_dir)
        info.update(file0)
      rescue
        print "some errors on touch, but dont mind...\n"
      end

      l_path = @src[:srcs][@target][:local_uri]
      p command = "open -a #{@browser} \'#{l_path}/?#{file}\'"
      system command
      p "If you get open error, try rackup from the src_dir."
      p "If you get 整形式になっていません, try login as a valid user."
      p "If you have errors on web, gem install sequel, rdtools, etc"
    end

    desc "rsync", "rsync files"
    #    map "--rsync" => "rsync"
    #    option :rsync
    def rsync
      p local = @l_dir
      p global = @src[:srcs][@target][:global_dir]
      p command = "rsync -auvz -e ssh #{local}/ #{global}"
      system command
    end

    desc "db FILE", "read datebase file"
    #    map "--database" => "database"
    def db(file_name)
      info = InfoDB.new(@l_dir)
      p info.show(file_name)
    end

    desc "show FILE", "display converted hikifile"
    #    map "--display" => "display"
    def show(file)
      body = HikiDoc.to_html(File.read(file))
      source = HTML_TEMPLATE
      title = File.basename(file)
      erb = ERB.new(source)
      t = File.open(file + ".html", "w")
      t.puts(erb.result(binding))
      t.close
      system "open #{t.path}"
    end

    desc "checkdb", "check database file"
    #    map "--checkdb" => "checkdb"
    def checkdb
      result = InfoDB.new(@l_dir).show_inconsist
      print (result == "") ? "db agrees with text dir.\n" : result
    end

    desc "rm [FILE]", "remove files"
    #    map "--remove" => "remove"
    def rm(file_name)
      p text_path = File.join(@l_dir, "text", file_name)
      p attach_path = File.join(@l_dir, "cache/attach", file_name)
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

      info = InfoDB.new(@l_dir)
      p "delete "
      del_file = info.delete(file_name)
      info.show_link(file_name)
      info.dump
    end

    desc "mv [FILE]", "move file"
    #    map "--move" => "move"
    def mv(files)
      begin
        p file1_path = File.join(@l_dir, "text", files[0])
        p file2_path = File.join(@l_dir, "text", files[1])
      rescue => evar
        puts evar.to_s
        puts "error on move_files, check the input format, especially comma separation."
        exit
      end
      return if file1_path == file2_path
      if File.exist?(file2_path)
        print ("moving target #{files[1]} exists.\n")
        print ("first remove#{files[1]}.\n")
        return
      else
        File.rename(file1_path, file2_path)
      end

      info = InfoDB.new(@l_dir)

      db = info.db

      pp file0 = db[files[0]]
      db.delete(files[0])
      db[files[1]] = file0
      db[files[1]][:title] = files[1] if db[files[1]][:title] == files[0]
      pp db[files[1]]

      db.each { |ele|
        ref = ele[1][:references]
        if ref.include?(files[0])
          p link_file = ele[0]
          link_path = File.join(@l_dir, "text", link_file)

          cont = File.read(link_path)
          if Kconv.iseuc(cont)
            print "euc\n"
            utf8_cont = cont.toutf8
            utf8_cont.gsub!(/#{files[0]}/, "#{files[1]}")
            cont = utf8_cont.toeuc
          else
            cont.gsub!(/#{files[0]}/, "#{files[1]}")
          end

          File.write(link_path, cont)

          ref.delete(files[0])
          ref << files[1]

          p cache_path = File.join(@l_dir, "cache/parser", link_file)
          begin
            File.delete(cache_path)
          rescue => evar
            puts evar.to_s
          end
        end
      }

      info.dump
    end

    desc "euc FILE", "translate file to euc"
    #    map "--euc" => "euc"
    def euc(file)
      p file_path = File.join(@l_dir, "text", file)
      cont = File.readlines(file_path)
      cont.each { |line| puts line.toeuc }
    end

    no_commands do
      def display_format(id, name, local, global, i_size, n_size, l_size, g_size)
        name_length = n_size - full_width_count(name)
        local_length = l_size - full_width_count(local)
        global_string = global.size < g_size ? global : global[0..g_size]
        [id.to_s.rjust(i_size), name.ljust(name_length),
         local.ljust(local_length),
         global_string.ljust(g_size)].join(" | ")
      end

      def full_width_count(string)
        string.each_char.select { |char| !(/[ -~｡-ﾟ]/.match(char)) }.count
      end

      def dump_sources
        file = File.open(DATA_FILE, "w")
        YAML.dump(@src, file)
        file.close
      end
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
    @src = { :target => 0, :editor_command => "open -a mi",
            :srcs => [{ :nick_name => "hoge", :local_dir => "hogehoge",
                        :local_uri => "http://localhost/~hoge",
                        :global_dir => "hoge@global_host:/hoge",
                        :global_uri => "http://hoge" }] }
    file = File.open(data_path, "w")
    YAML.dump(@src, file)
    file.close
  end
  private_class_method :create_file_if_not_exists, :create_data_file, :init_data_file
end
