#!/bin/zsh -x

TS=$1
OUT=$2
CUT_FIRST='00:00:01.500' # 冒頭1.5秒を切る

BASE=$(basename $TS .ts)
[ "${BASE}.ts" = "$(basename $TS)" ] || exit 1

INFO_COMMAND="avconv -i ${TS}"
VIDEO_INFO=$(${INFO_COMMAND} 2>info)

V720STREAM=$(cat info | grep Stream | grep 720 | sed -e 's/^.\+#//' | sed -e 's/\[.\+//' | sed -e 's/\./:/')
V1440STREAM=$(cat info | grep Stream | grep 1440 | sed -e 's/^.\+#//' | sed -e 's/\[.\+//' | sed -e 's/\./:/')
AUDIO_STREAM=$(cat info | grep Stream | grep 'Audio: aac' | sed -e 's/^.\+#//' | sed -e 's/\[.\+//' | sed -e 's/\./:/')

echo $USE_VIDEO_STREAM

rm info

if $V720STREAM ; then
  USE_VIDEO_STREAM=$V1440STREAM
else
  USE_VIDEO_STREAM=$V720STREAM
fi
echo $USE_VIDEO_STREAM

DROP_COMMAND=" -map ${V720STREAM} -map ${AUDIO_STREAM} \
  -ss ${CUT_FIRST} \
  -vcodec copy \
  -acodec libfaac -ac 2 -ar 48000 -ab 128k \
"

avconv -y -i ${TS} ${DROP_COMMAND} "${OUT}"
