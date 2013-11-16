#!/bin/bash
function simulate {
   SIM_LOG=`hspice $1 2>/dev/null`
   GAIN=`echo "$SIM_LOG" | grep "gain_ohm=" | awk '{printf "%f\n",$2}' `
   FREQ3DB=`echo "$SIM_LOG" | grep "freq3db=" | awk '{printf "%f\n",$2}' `
   FREQ3DB=`echo "$SIM_LOG" | grep "freq3db=" | awk '{printf "%f\n",$2}' `
   POWER=`echo "$SIM_LOG"| grep -E "voltage.*watts" | sed 's/[^0-9]*\([0-9.]\+\)\([a-z]\).*/\1 \2/' | awk 'BEGIN { m=-3 } { if($2=="m") print $1"e"m; else print "Check Units" }'`
   printf "Gain: %e BW: %e Power: %e\n" $GAIN $FREQ3DB $POWER
}

function gradient {
   BASE=$(simulate $1)
   f=(`echo "$BASE" | awk '{print $2" "$4" "$6}'`)
   echo "${f[@]}"
   CURRENT_VECTOR=(`sed -e 's/\.param Id1=\([0-9\.]\+\)u, Id2=\([0-9\.]\+\)u, Id3=\([0-9\.]\+\)u.*/\1 \2 \3/p' -n $1| awk '{print $1" " $2" " $3" " }'`)
   # Negative increment (recover power)
   #NEW_CURRENTS=( `echo "${CURRENT_VECTOR[@]}" | awk '{print $1-0.1" "$2-0.1" "$3-0.1}'` )
   # Positive incremente (recover bw)
   NEW_CURRENTS=( `echo "${CURRENT_VECTOR[@]}" | awk '{print $1+0.1" "$2+0.1" "$3+0.1}'` )
   k=1
   for current in ${NEW_CURRENTS[@]}; do
   cp $1 $1.gradient.sp
   sed -e 's/\(\.param.*Id'$k'=\)[0-9\.]\+\(u.*\)/\1'${current}'\2/' $1.gradient.sp -i
   let k++ 
   RESULT=$(simulate $1.gradient.sp) 	
   GRAD=(`echo "$RESULT" | awk '{print ($2-'${f[0]}')/'${f[0]}'" "($4-'${f[1]}')/'${f[1]}'" "($6-'${f[2]}')/'${f[1]}'}'` )
   echo "${GRAD[@]}"
   done
}

function oneDimensionalSweep {
# Argumets
#  1. script
#  2. Current number 1 to 3
#  3. Iterations (D=0.1u)
   BASE=$(simulate $1)
   echo "$BASE"
   k=$2
   N=$3
   #f=(`echo "$BASE" | awk '{print $2" "$4" "$6}'`)
   #echo "${f[@]}"
   CURRENT_VECTOR=(`sed -e 's/\.param Id1=\([0-9\.]\+\)u, Id2=\([0-9\.]\+\)u, Id3=\([0-9\.]\+\)u.*/\1 \2 \3/p' -n $1| awk '{print $1" " $2" " $3" " }'`)
   for n in $(seq 1 $N); do
   # Negative incremente (recover power)
       NEW_CURRENTS=( `echo "${CURRENT_VECTOR[@]}" | awk '{print $1-'$n'*0.1" "$2-'$n'*0.1" "$3-'$n'*0.1}'` ) 
   # Positive incremente (recover bw)
   #    NEW_CURRENTS=( `echo "${CURRENT_VECTOR[@]}" | awk '{print $1+'$n'*0.1" "$2+'$n'*0.1" "$3+'$n'*0.1}'` ) 
       echo "${NEW_CURRENTS[@]}"
       current=${NEW_CURRENTS[$(expr $k-1)]}
       cp $1 $1.step.sp
       sed -e 's/\(\.param.*Id'$k'=\)[0-9\.]\+\(u.*\)/\1'${current}'\2/' $1.step.sp -i
       RESULT=$(simulate $1.step.sp) 	
       echo "$RESULT"
       #GRAD=(`echo "$RESULT" | awk '{print ($2-'${f[0]}')/'${f[0]}'" "($4-'${f[1]}')/'${f[1]}'" "($6-'${f[2]}')/'${f[1]}'}'` )
       #echo "${GRAD[@]}"
   done
}

if [ $# -lt "1" ];then
    echo "Usage: exp [-grad|-sweep] deck.sp [current]"
elif [ "$1" == "-grad" ]; then
    gradient $2
elif [ "$1" == "-sweep" ]; then  
    oneDimensionalSweep $2 $3 $4
fi

# Hopefully we Advance in gradient direction
#simulate $SPICE_DECK
exit
