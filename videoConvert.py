import os
import sqlite3
import subprocess
import time
from pathlib import Path

# Set input and output folders
input_folder = os.environ.get('INPUT_FOLDER')
output_folder = os.environ.get('OUTPUT_FOLDER')
archive_folder = os.environ.get('ARCHIVE_FOLDER')
encoder = os.environ.get('ENCODER')

# Set database file
db_file = os.environ.get('DB_FILE')

# Set timezone to Mountain Standard Time
os.environ['TZ'] = 'MST'

# Create database table if it doesn't exist
conn = sqlite3.connect(db_file)
cursor = conn.cursor()
cursor.execute("CREATE TABLE IF NOT EXISTS converted_videos (id INTEGER PRIMARY KEY AUTOINCREMENT, original_file_name TEXT, original_file_date TIMESTAMP, converted_file_name TEXT, converted_file_date TIMESTAMP, claim_number TEXT, ad_notes TEXT);")
conn.commit()

# Loop through each file in the input folder
for file_path in Path(input_folder).glob('*'):
    if file_path.suffix.lower() in ['.mp4', '.wmv', '.3gp', '.mts', '.avi', '.mov']:
        file_name = file_path.name
        output_file_name = f"output_{file_path.stem}.mp4"
        output_file_path = os.path.join(output_folder, output_file_name)

        # Check if the file has already been converted
        cursor.execute("SELECT original_file_name FROM converted_videos WHERE original_file_name = ?", (file_name,))
        if cursor.fetchone():
            print(f"Video {file_name} has already been converted. Skipping...")
        else:
            # Record original file date
            original_file_date = int(file_path.stat().st_mtime)

            # Transcode
            result = subprocess.run([encoder, str(file_path), '-out', output_file_path, '-preset', 'H264_MAIN_720p', '-resize', 'keepAspect'])

            # Check if transcode encountered any errors
            if result.returncode == 0:
                # Archive the original input video file
                os.rename(file_path, os.path.join(archive_folder, file_name))

                # Record converted file date
                converted_file_date = int(time.time())

                # Insert the converted video file name, original file name, claim number, and ad notes to the database with NULL values for claim number and ad notes
                cursor.execute("INSERT INTO converted_videos (original_file_name, original_file_date, converted_file_name, converted_file_date, claim_number, ad_notes) VALUES (?, ?, ?, ?, NULL, NULL);", (file_name, original_file_date, output_file_name, converted_file_date))
                conn.commit()

                print(f"Video {file_name} converted and moved to {output_folder}")
            else:
                print(f"Failed to convert video {file_name}.")

conn.close()