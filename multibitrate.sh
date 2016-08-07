#!/bin/bash
# multibitrate ffmpeg hls streaming
#
# usage:
#   $ python -m SimpleTornadoServer 8000
#
#   $ ffplay http://0.0.0.0:8000/hls/playlist.m3u8
#
#   $ http://127.0.0.1:8000/assets/grind.html

NOARGS=65

function usage() {
    echo "description"
    echo "  usage: ./multibitrate.sh <source>"
    exit $NOARGS
}

[[ $# -eq 0 ]] && usage

[ -d hls/240p ] || mkdir -p hls/240p
[ -d hls/260p ] || mkdir -p hls/360p

SOURCE=$1

cat > hls/playlist.m3u8 << EOF
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=400000
http://0.0.0.0:8000/hls/240p/index.m3u8
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=750000
http://0.0.0.0:8000/hls/360p/index.m3u8
EOF

# HLS="-force_key_frames 0:04:00 -hls_time 4 -hls_list_size 8 -hls_wrap 9 -hls_flags delete_segments -start_number 1"
HLS="-hls_time 4 -hls_list_size 8 -hls_wrap 8 -hls_flags delete_segments -start_number 1"

ffmpeg -v verbose -i $SOURCE \
    -vcodec libx264 -acodec aac -ac 2 -strict -2 \
    -vf "[in]yadif=0:-1:0,scale=426:340[out]" -crf 18 -profile:v baseline \
    -r 25 -g 100 -force_key_frames "expr:gte(t,n_forced)" \
    -maxrate 400k -bufsize 800k -pix_fmt yuv420p -flags -global_header \
    -threads 2 $HLS hls/240p/index.m3u8 \
    -vcodec libx264 -acodec aac -ac 2 -strict -2 \
    -vf "[in]yadif=0:-1:0,scale=640:-1[out]" -crf 18 -profile:v baseline \
    -r 25 -g 100 -force_key_frames "expr:gte(t,n_forced)" \
    -maxrate 750k -bufsize 1500k -pix_fmt yuv420p -flags -global_header \
    -threads 4 $HLS hls/360p/index.m3u8
