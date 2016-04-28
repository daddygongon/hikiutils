cont = File.readlines('info.db', encoding: 'EUC-JP:UTF-8')

cont.each{|line| puts line}
