#打印指定行前5行
seq 20 | sed -rn ':a;/12/!{N;ba};:b;/([^\n]+\n){5}/{s#^[^\n]+\n##;bb};p'