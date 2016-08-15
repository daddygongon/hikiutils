# 目的

hikiutilsを直感的なオプションに替える

# 背景

hikiutilsはhikiの編集を効率的に行うためのutilitiesを提供している．
しかし，そこで使われているoptionsは，あまり直感的でない．
そこで，optionsをshellで使われているコマンドを元に，より直感的なものに変更する．

# 具体例

```
hiki --update FILE
```
は変更したファイルをhikiに反映させるコマンドです．この操作を
```
hiki touch FILE
```
とすると，FILEを最新の状態に変更するという意味で通じると思います．

# 使用法

"hiki" をコマンド名としています．

Usage: hiki [options]
```
-v, --version                    show program Version.
-s, --show                       show sources
-a, --add                        add sources info
-t, --target VAL                 set target id
-e, --edit FILE                  open file
-l, --list [FILE]                list files
-u, --update FILE                update file
-r, --rsync                      rsync files
--database FILE              read database file
--display FILE               display converted hikifile
-c, --checkdb                    check database file
--remove FILE                remove file
--move FILES                 move file1,file2
--euc FILE                   translate file to euc
```
