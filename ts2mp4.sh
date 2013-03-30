#!/bin/bash -x

TS=$1
OUT=$2
WIDTH=$3
HEIGHT=$4
BASE=$(basename $TS .ts)
[ "${BASE}.ts" = "$(basename $TS)" ] || exit 1

#CPU_CORES=0
CPU_CORES=$(/usr/bin/getconf _NPROCESSORS_ONLN)

X264_HIGH_HDTV="-f mp4 \
  -aspect 16:9 -s ${WIDTH}x${HEIGHT} \
  -map 0:0:0:0 -map 0:1:0:1 \
  -vf yadif=1:-1,scale=${WIDTH}:${HEIGHT} \
  -deinterlace \
  -vcodec libx264 x264opts \
  -fpre preset/libx264-hq-ts.ffpreset \
  -r 30000/1001 -b 20000k -rc_init_occupancy 2000k -bufsize 20000k -maxrate 25000k \
  -acodec libfaac -ac 2 -ar 48000 -ab 128k -threads ${CPU_CORES}"

OUT = sed -e 's/ /\ /g' ${OUT}
ffmpeg -y -i $TS ${X264_HIGH_HDTV} "${OUT}"

exit
