#!/bin/sh

# This script converts video files in a specified input folder to a standard format using FFmpeg,
# archives the original input file, and saves the converted file to a specified output folder.
# It also records information about each converted file in a SQLite database.

# Set input and output folders
input_folder="/app/content/input/"
output_folder="/app/content/output/"
archive_folder="/app/content/archive/"

# Set standard video format
codec="libx264"  # You can specify the desired codec here

# Set database file
db_file="/app/content/videoConvert.db"

# Create database table if it doesn't exist
sqlite3 "$db_file" "CREATE TABLE IF NOT EXISTS converted_videos (id INTEGER PRIMARY KEY AUTOINCREMENT, original_file_name TEXT, converted_file_name TEXT, claim_number TEXT, ad_notes TEXT);"

# Loop through each file in the input folder
for file_path in "$input_folder"*; do
  if [[ "$file_path" == *.mp4 || "$file_path" == *.wmv || "$file_path" == *.3gp || "$file_path" == *.mts || "$file_path" == *.avi || "$file_path" == *.mov ]]; then  # Check if the file is a video
    file_name="${file_path##*/}"
    
    output_file_name="output_${file_name%.*}.mp4"  # Prefix "output_" to the original file name
    output_file_path="$output_folder$output_file_name"

    # Check if the file has already been converted
    if sqlite3 "$db_file" "SELECT original_file_name FROM converted_videos WHERE original_file_name = '$file_name';" | grep -q "$file_name"; then
      echo "Video $file_name has already been converted. Skipping..."
    else
      # Convert the video to the standard format and write to the output folder
      ffmpeg -i "$file_path" -c:v "$codec" "$output_file_path"
      
      # Check if ffmpeg encountered any errors
      if [ $? -eq 0 ]; then
        # Archive the original input video file
        mv "$file_path" "$archive_folder/$file_name"

        # Insert the converted video file name, original file name, claim number, and ad notes to the database with NULL values for claim number and ad notes
        sqlite3 "$db_file" "INSERT INTO converted_videos (original_file_name, converted_file_name, claim_number, ad_notes) VALUES ('$file_name', '$output_file_name', NULL, NULL);"

        echo "Video $file_name converted and moved to $output_folder"
      else
        echo "Failed to convert video $file_name."
      fi
    fi
  fi
done