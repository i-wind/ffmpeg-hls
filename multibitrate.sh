#!/bin/bash
# multibitrate ffmpeg hls streaming
#
# usage:
#   $ python -m SimpleTornadoServer 8000
#
#   $ ffplay http://0.0.0.0:8000/hls/playlist.m3u8

NOARGS=65

function usage() {
    echo "description"
    echo "  usage: ./multibitrate.sh <source>"
    exit $NOARGS
}

[[ $# -eq 0 ]] && usage

[ -d hls ] || mkdir hls

SOURCE=$1

cat > hls/playlist.m3u8 << EOF
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=400000
http://0.0.0.0:8000/hls/index1.m3u8
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=750000
http://0.0.0.0:8000/hls/index2.m3u8
EOF

HLS="-hls_time 4 -hls_list_size 8 -hls_wrap 9 -hls_flags delete_segments -start_number 1"

ffmpeg -v verbose -i $SOURCE -vcodec libx264 -acodec aac -ac 2 -strict -2 \
    -vf "[in]yadif=0:-1:0,scale=426:-1[out]" -crf 18 -profile:v baseline \
    -maxrate 400k -bufsize 800k -pix_fmt yuv420p -flags -global_header \
    -threads 2 $HLS hls/index1.m3u8 -vcodec libx264 -acodec aac -ac 2 \
    -strict -2 -vf "[in]yadif=0:-1:0,scale=640:-1[out]" -crf 18 \
    -profile:v baseline -maxrate 750k -bufsize 1500k -pix_fmt yuv420p \
    -flags -global_header -threads 4 $HLS hls/index2.m3u8
