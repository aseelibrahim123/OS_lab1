Simple Antivirus Daemon — OS Lab 1

1. Project Overview

This project implements a simplified antivirus system using Bash shell scripts on Ubuntu Linux. It monitors a directory for changes, detects potentially malicious files based on their extensions or contents, and moves detected files to a quarantine directory.

The project includes:

antivirusd.sh — Continuously monitors a directory and scans it when changes are detected.

restore.sh — Allows users to restore quarantined files, permanently delete them, or leave them in quarantine.

antivirus-cron.sh — Performs antivirus scanning through a cron-based scheduled job.

Makefile — Provides commands to run the antivirus daemon and restore tool, with a pre-build step.

whitelist.txt — Stores the absolute paths of files marked as safe.

directory-info.last — Stores the previous directory listing.

directory-info.new — Stores the current directory listing for comparison.

cron.log — Records the cron script's startup message.

Folder Hierarchy

OS-lab1/
├── antivirusd.sh
├── restore.sh
├── antivirus-cron.sh
├── Makefile
├── README.md
├── whitelist.txt

 whitelist.txt is created when a file is restored for the first time, if it does not already exist.

2. Prerequisites and Installation

Requirements

Ubuntu Linux

Bash shell

Cron service for the cron bonus

These utilities are normally available on Ubuntu.

Install the Required Packages

Open a terminal and run:

sudo apt update
sudo apt install bash coreutils grep diffutils make cron

Start and enable the cron service:

sudo systemctl enable --now cron

3. Antivirus Daemon — antivirusd.sh

Purpose

The antivirus daemon monitors the specified source directory and scans its files when a change is detected.

Usage

./antivirusd.sh <scan_dir> <malicious_dir> <interval_secs>

Arguments:

scan_dir: Directory containing the files to monitor.

malicious_dir: Directory where flagged files are quarantined.

interval_secs: Number of seconds between checks.

Example:

./antivirusd.sh test result 5

This command monitors the test/ directory, uses result/ as the quarantine directory, and checks for changes every five seconds. 

How It Works

The script checks whether directory-info.last exists.

If it does not exist, the script scans the source directory immediately and creates the initial directory listing.

After each interval, the script generates directory-info.new using ls -l.

It compares the current listing with the previous listing using diff.

If the listings are identical, the script waits for the next interval without scanning.

If the listings differ, the script scans the directory and updates directory-info.last.

When a file is identified as malicious, it is moved to the quarantine directory and a message is printed to the terminal.

The daemon continues running until it is stopped, for example, by pressing Ctrl+C.

Malicious File Detection

The required detection lists are hardcoded inside the scan_virus() function in antivirusd.sh.

Flagged extensions

The case statement checks for the following extensions:

*.exe|*.bat|*.vbs|*.scr|*.ps1)

Flagged content keywords

The grep command checks file contents for these keywords:

grep -Eiq 'virus|trojan|malware|worm|ransomware' "$file"

The options mean:

-E: Enables extended regular expressions.

-i: Ignores case, so uppercase and lowercase variations match.

-q: Suppresses matching lines and returns a status indicating whether a match was found.

A file is flagged if its filename matches one of the specified extensions or its contents contain one of the specified keywords, unless its absolute path is present in the whitelist.

When a file is flagged, the script moves it to malicious_dir and prints:

<file> is malicious and it is DELETED

The original file is removed from the monitored directory by the move operation.

4. Restore Tool — restore.sh

Purpose

The restore tool allows users to review files in quarantine and decide whether to restore them, permanently delete them, or leave them unchanged.

Usage

./restore.sh <scan_dir> <malicious_dir>

Example:

./restore.sh test malicious

How It Works

The script checks whether the quarantine directory is empty.

If it is empty, the script prints:

No malicious files to review.

Otherwise, it displays the available files as a numbered list.

The user enters the number of the file to review.

The script validates the number to ensure that it is numeric and within the available range.

The user chooses one of three actions:

Option 1 — Restore file: Moves the selected file back to the source directory and adds its absolute path to whitelist.txt.

Option 2 — Permanently delete file: Removes the selected file from quarantine.

Option 3 — Go back to file list: Leaves the selected file unchanged and returns to the list.

Terminal Messages

After a successful restore, the script prints a message such as:

Restored example.txt to test

After permanent deletion, it prints:

example.txt permanently deleted.

If the quarantine directory is empty, it prints:

No malicious files to review.

The restore tool repeats the process until there are no files left to review.
5. Makefile

The Makefile provides convenient targets for running the daemon and restore tool. Its pre-build target creates the quarantine directory if it does not already exist.  

pre-build: Creates the quarantine directory using mkdir -p.

antivirus: Runs antivirusd.sh with the specified arguments.

restore: Runs restore.sh with the specified arguments. 

Running the Makefile

First, navigate to the project directory:

cd ~/OS-lab1

To start the antivirus daemon:

make antivirus SCAN_DIR=test MALICIOUS_DIR=malicious INTERVAL_SEC=5

To start the restore tool:

make restore SCAN_DIR=test MALICIOUS_DIR=malicious

To run only the pre-build step:

make pre-build MALICIOUS_DIR=malicious

Note: The Makefile uses the variables SCAN_DIR, MALICIOUS_DIR, and INTERVAL_SEC. These values must be supplied when running the relevant targets unless defaults are defined in the Makefile.

Each command line in the Makefile must begin with a literal tab character, as required by Make.

6. Bonus 1 — Cron-Based Antivirus

Purpose

antivirus-cron.sh implements the scanning and quarantine behavior as a scheduled job rather than a continuously running daemon.

The script accepts two arguments:

./antivirus-cron.sh <scan_dir> <malicious_dir>

For example:

./antivirus-cron.sh test malicious

The script checks the directory listing and scans when a change is detected. On the first run, it scans immediately and creates the initial listing.

The script also appends a startup message to cron.log.

Important Configuration

The current antivirus-cron.sh contains absolute paths specific to the development environment:

WHITELIST_FILE="/home/aseel/OS-lab1/whitelist.txt"

and:

/home/aseel/OS-lab1/cron.log

Update these paths if the project is stored elsewhere. The cron script also needs to use the same absolute-path comparison as antivirusd.sh for whitelist checks to work consistently.

Configure the Cron Job

Step 1: Verify that cron is installed and running.

sudo systemctl status cron

Step 2: Open your personal crontab.

crontab -e

Step 3: Add the following entry, replacing the project path if necessary:

* * * * * /home/aseel/OS-lab1/antivirus-cron.sh /home/aseel/OS-lab1/test /home/aseel/OS-lab1/malicious 

This schedules the script once every minute. The script attempts to delay execution until second 23 using its sleep command.

Cron itself has minute-level scheduling precision; the delay is implemented inside the script. Ensure the delay calculation handles cases where the script starts after second 23.

Step 4: Save and exit the editor.

Step 5: Check the log file.

cat /home/aseel/OS-lab1/cron.log

You can also inspect cron service logs to troubleshoot scheduled executions.

Cron Expression for Every Third Friday at 12:31 AM

The intended schedule is 12:31 AM on the third Friday of each month.

Standard cron does not portably express “third Friday” using a single ordinary five-field expression, because day-of-month and day-of-week fields commonly use OR semantics.

A practical approach is to schedule every Friday at 12:31 AM:

31 0 * * 5

Then have a wrapper or the scheduled script check whether the date falls between the 15th and 21st of the month. Only run the scan when both conditions are true:

The day of the week is Friday.

The day of the month is between 15 and 21, inclusive.

This avoids accidentally running on other Fridays or on other dates in the third week.

7. Bonus 2 — Persistent Whitelist

Purpose

The whitelist prevents a file that was incorrectly flagged from being quarantined repeatedly.

The whitelist is stored in:

whitelist.txt

Each entry contains the absolute path of a file that has been restored and marked as safe.

How a File Is Added

When the user selects Option 1 — Restore file in restore.sh, the script:

Moves the selected file back to the source directory.

Creates whitelist.txt if it does not exist.

Calculates the file's absolute path using realpath.

Appends that path to the whitelist.

The relevant commands are:

touch "$WHITELIST_FILE"
realpath "$scan_dir/$filename" >> "$WHITELIST_FILE"

For example, a whitelist entry might look like:

/home/aseel/OS-lab1/test/example.txt

How the Daemon Checks the Whitelist

At the beginning of each file's scan, antivirusd.sh calculates the file's absolute path and checks whether an exact match exists in whitelist.txt:

file_path=$(realpath "$file")

if [ -f "$WHITELIST_FILE" ] && grep -Fxq -- "$file_path" "$WHITELIST_FILE"; then
    echo "$filename is whitelisted. Skipping scan"
    continue
fi

The options -F, -x, and -q mean that the search treats the path as a literal string, requires an entire-line match, and suppresses normal matching output.

If the path is found, the daemon skips the file and continues to the next one. Otherwise, it checks the file's extension and contents normally.

Because the whitelist is stored in a file, its entries persist after the daemon stops or restarts.

Important: The current antivirusd.sh and restore.sh use a relative path for whitelist.txt, while antivirus-cron.sh uses an absolute path. The cron script should also compare canonical absolute paths using realpath so the same whitelist entries are recognized consistently. Whitelist paths are location-specific, so moving or renaming a restored file may require updating its entry.

8. Stopping and Troubleshooting

Stop the Antivirus Daemon

If the daemon is running in the foreground, press:

Ctrl+C

Remove the Cron Job

Open the crontab:

crontab -e

Remove the entry associated with antivirus-cron.sh, then save and exit.
