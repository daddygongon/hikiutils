require 'fileutils'
entries = Dir.entries('figs')
entries.each{|file|
  sp=file.split('.')
  if sp[2]=='jpq'
    target=sp[0]+'.'+sp[1]+'.jpg'
    p command = "mv figs/#{file} figs/#{target}"
    system command
  end
}
