#!/bin/sh

# Set input and output folders
input_folder="/app/content/input/"
output_folder="/app/content/output/"
archive_folder="/app/content/archive/"

# Set standard video format
codec="libx264"  # You can specify the desired codec here

# Set log file
log_file="/app/content/converted.txt"
error_log_file="/app/content/error.txt"

# Create log file if it doesn't exist
touch $log_file
touch $error_log_file

# Loop through each file in the input folder
for file_path in $input_folder*; do
  if [[ $file_path == *.mp4 ]]; then  # Check if the file is a video
    file_name="$(basename $file_path)"
    output_file_name="output_$file_name"  # Prefix "output_" to the original file name
    output_file_path="$output_folder$output_file_name"

    # Check if the file has already been converted
    if grep -q "$file_name" "$log_file"; then
      echo "Video $file_name has already been converted. Skipping..."
    else
      # Convert the video to the standard format and write to the output folder
      ffmpeg -i $file_path -c:v $codec $output_file_path
      
      # Check if ffmpeg encountered any errors
      if [ $? -eq 0 ]; then
        # Archive the original input video file
        mv $file_path $archive_folder/$file_name

        # Write the converted video file name to the log file
        echo "$file_name" >> $log_file

        echo "Video $file_name converted and moved to $output_folder"
      else
        echo "Failed to convert video $file_name. Check $error_log_file for details."
      fi
    fi
  fi
done