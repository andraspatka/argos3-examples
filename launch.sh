#!/bin/bash
# ================================================================================
# Created by: Patka Zsolt-András
# On: 13.07.2019
# Last revision: 16.02.2020
# This script makes it easier to clean, build, debug and run the ARGoS experiment
# 
# Arguments:$1	The job to execute, can be:
#                   capture     takes the frames created from an argos capture,
#                               creates a video from them and then deletes them.
#                               filename is equal to $2
#                   clean       removes the ${build_dir} directory
#					build 		builds the project
#					run			runs the experiment
#					build-run   builds the project and runs the experiment	
#					build-debug builds the project and stars the experiment in
#								debug mode
#			$2	The name of the scene
#
# build - requires no $2
# clean - requires no $2
# ================================================================================

# Subtasks implemented as functions

build_dir="build"

# Clean subtask
function f_clean {
	rm -r ${build_dir}
	mkdir ${build_dir}
}

# Build subtask
function f_build {
	if ! [[ -d ${build_dir} ]]; then
		mkdir ${build_dir}
	fi
	cd ${build_dir}
	cmake -DCMAKE_BUILD_TYPE=Release ..
	make
}

# Run subtask
function f_run {
	isBuild=$(pwd | grep ${build_dir})
	if ! [[ -z ${isBuild} ]]; then
		cd ..
	fi
	
	argos3 -c ${scene_name}
}

# Debug subtask
function f_build_debug {
	f_clean
	cd ${build_dir}
	cmake -DCMAKE_BUILD_TYPE=Debug ..
	make
	f_run
}

# Capture subtask.
function f_capture {
    frames=$(ls | egrep "^frame_[0-9]{5}.png")
    dir_name=$(echo "capture_$cap_output")
    cd captures
    mkdir ${dir_name}
    mkdir ${dir_name}/frames
    cd ..
    for frame in ${frames};
    do
        mv ${frame} captures/${dir_name}/frames/${frame}
    done
    ffmpeg -framerate 24 -i captures/${dir_name}/frames/frame_%05d.png \
        -vf scale=1280:-2 -c:v libx264 -profile:v high -crf 20 -pix_fmt yuv420p \
        captures/${dir_name}/${cap_output}.mp4
}

# ================================================================================
if (( $# < 1 || $# > 2 )); then # Invalid number of arguments
	echo "Invalid usage. Correct usage: qswarm <job> [<scene_name>]"
	exit 1;
fi

job=$1
cap_output=$2
if [[ "$job" != "build" && "$job" != "capture" && "$job" != "clean" ]]; then
    scene_name="experiments/$2.argos"
    if ! [[ -a ${scene_name} ]]; then
        echo "Could not find the scene: $scene_name"
        exit 1;
    fi
fi
if [[ "$1" == "capture" && -z ${cap_output} ]]; then
    echo "Invalid usage. Correct usage: qswarm capture [output_file_name]"
    exit 1;
fi


case $job in
    clean)
        f_clean
        ;;
    capture)
        f_capture
        ;;
	build)
		f_build
		;;
	run)
		f_run
		;;
	build-run)
		f_build
		f_run
		;;
	build-debug)
		f_build_debug
		;;
	*) echo "Incorrect job, available jobs: clean, build, run, build-run and build-debug, capture"
esac

exit 0;
