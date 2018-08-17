#!/bin/bash

# Convert an image into emoji format for Slack
#
# Usage:
#   emojify [-c] <image path> [output path]
#

##########################
# Constatnts
##########################

slack_max_size=63 # Use a bit below to account for possible rounding errors in compression

##########################
# Pre-check
##########################

if [ -z $(which magick) ]; then
    echo "Imagemagick is required for this script. Please install it first by running 'brew install imagemagick'."
    exit 1
fi

##########################
# Functions
##########################

usage() {
    echo -e "usage: emojify [-c|--crop] <image path> [output name]"
    echo -e "\t-c|--crop: center crop"
    exit 1
}

##########################
# Parse arguments
##########################

crop=false
image_path=""
output_path=""

if [ $# -lt 1 ]; then
	echo -e "ERROR: Too few arguments.\n"
	usage
elif [ $# -eq 1 ]; then
	image_path="$1"
    output_path="output.${image_path##*.}"
elif [ $# -eq 2 ]; then
    if [ "$1" == "-c" ] || [ "$1" == "--crop" ]; then
    	crop=true
        image_path="$2"
        output_path="output.${image_path##*.}"
    else
        image_path="$1"
        output_path="$2"
    fi
elif [ $# -eq 3 ]; then
    if [ "$1" == "-c" ] || [ "$1" == "--crop" ]; then
    	crop=true
        image_path="$2"
        output_path="$3"
    else
        echo -e "ERROR: Incorrect arguments.\n"
        usage
    fi
fi


##########################
# Main Script
##########################

image_width=$(magick identify -format "%[w]" "$image_path")
image_height=$(magick identify -format "%[h]" "$image_path")

echo "Height $image_height"
echo "Width: $image_width"
echo "Crop: $crop"
echo "Image Path: $image_path"
echo "Output Path: $output_path"

if [ $crop == true ]; then
    min_size=0
    offset=0

    if [ $image_width -lt $image_height ]; then
        min_size=$image_width
        offest=$(( ($image_height-$image_width) / 2 ))
    else
        min_size=$image_height
        offest=$(( ($image_width-$image_height) / 2 ))
    fi

    magick convert -crop "$min_size"x"$min_size"+$offest "$image_path" "$output_path"

    image_path="$output_path"
    image_width=$min_size
    image_height=$min_size
fi

if [ $image_width -le $image_height ]; then
    magick convert -resize x128 "$image_path" "$output_path"
else
    magick convert -resize 128x "$image_path" "$output_path"
fi

photo_size=$(( `du -k "$output_path" | cut -f1` ))

echo "Current Photo Size: $photo_size kb"

if [ $photo_size -gt $slack_max_size ]; then
    echo "Compressing to fit Slack size requirements"
    quality=`echo "100 * ($slack_max_size/$photo_size)" | bc -l`
    magick convert -quality $quality "$output_path" "$output_path"
fi
