require 'kconv'
cont=File.read('./info.db')
p Kconv.iseuc(cont)
print cont.toutf8
