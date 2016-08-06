#!/bin/bash
# simple ffmpeg hls streaming
#
# usage:
#   $ python -m SimpleTornadoServer 8000
#
#   $ ffplay http://0.0.0.0:8000/hls/playlist.m3u8

NOARGS=65

function usage() {
    echo "description"
    echo "  usage: ./start.sh <source>"
    exit $NOARGS
}

[[ $# -eq 0 ]] && usage

[ -d hls ] || mkdir hls

SOURCE=$1

ffmpeg -re -i $SOURCE -vf "scale=640:-1" -acodec libfaac -b:a 128k \
    -c:v libx264 -b:v 750k -flags -global_header -f segment -segment_time 10 \
    -segment_list hls/playlist.m3u8 -segment_format mpegts hls/playlist_%05d.ts
