cat $1 | awk -F ':' '{
        f1=""
        for(i=1; i<=NF; i++) {
                tmp=match($i, /\](.*)[[:space:]]inserts/,a)
                if(tmp) {
                        f1=a[1]
                        gsub(",","",f1)
                }
                tmp=match($i, /.*ips=(.*)[[:space:]]/,b)
                if(tmp) {
                        f2=b[1]
                        gsub(",","",f2)
                }
        }
        if (f1) 
        print f1/1000","f2
}'
