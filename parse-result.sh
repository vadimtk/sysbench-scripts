cat $1 | awk -F ',' '{
        f1=""
        for(i=1; i<=NF; i++) {
                tmp=match($i, /\[[[:space:]]*(.*)s\]/,a)
                if(tmp) {
                        f1=a[1]
                }
                tmp=match($i, /[[:space:]]*tps:[[:space:]]+(.*)/,b)
                if(tmp) {
                        f2=b[1]
                }
        }
        if (f1) 
        print f1","f2
}'
