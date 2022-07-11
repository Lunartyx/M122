#! /bin/bash

# employee
user_group="employees"

company_group="MusterGMBH"
# Wo werden die user erstellt
former_emp_dir="/mnt/c/Users/Desktop/Test/"
# Struktur des neuen Home directories
home_directory_contains=("documents" "images" "videos" "archive")

log_file="info.log"
# csv Datei Format
# FamiliennameFirst-name;kürzel;personummer;addresse;PLZ;Geburi;abteilung;eintritt;austritt;


while read -r line; do
    surname=$(echo "$line" | awk -F';' '{printf "%s", $1}' | tr -d '"')
    first_name=$(echo "$line" | awk -F';' '{printf "%s", $2}' | tr -d '"')
    abbreviation=$(echo "$line" | awk -F';' '{printf "%s", $3}' | tr -d '"')
    address=$(echo "$line" | awk -F';' '{printf "%s", $4}' | tr -d '"')
    zip=$(echo "$line" | awk -F';' '{printf "%s", $5}' | tr -d '"')

    department=$(echo "$line" | awk -F';' '{printf "%s", $8}' | tr -d '"')
    # entry=$(echo "$line" | awk -F';' '{printf "%s", $7}' | tr -d '"')
    exit=$(echo "$line" | awk -F';' '{printf "%s", $10}' | tr -d '"')

    # User existing?
    if [ ! $(getent group $user_group) ]; then
        echo -e "[$(date +" %D %T") ] group $user_group not exists,  creating.." >>$log_file
        groupadd $user_group
    fi
    if [ ! $(getent group $company_group) ]; then
        echo -e "[$(date +" %D %T") ] group $company_group not exists, creating..">>$log_file
        groupadd $company_group
    fi

    # user account existing?
    getent passwd $surname 2 2 >/dev/null &>1
    if [ $? -eq 0 ]; then
        echo "[$(date +" %D %T") ] user $surname exists">>$log_file

        # With this account?
        if [ ! $(getent group $department) ]; then
            echo -e "[$(date +" %D %T") ] group $department not exists, creating..">>$log_file
            groupadd $department
        fi
        # department changed?
        # is user in listed group?
        if id -nG "$surname" | grep -qw "$department"; then
            echo "[$(date +" %D %T") ] $surname belongs to $department">>$log_file
        else
            echo "[$(date +" %D %T") ] $surname does not belong to $department">>$log_file
            # add user to the new department and remove at from old department, dont forget to add the company group
            usermod -G $department,$company_group $surname
        fi

        #Leaving date occured?
        if [ $exit ]; then
            echo "[$(date +" %D %T") ] $surname left the company on $exit, remove $surname account">>$log_file
            # the content of the home directory should be moved to the personnel archive «Former Employees», which belongs to the Personnel group.
            zip -r  $former_emp_dir/$surname.zip /home/$surname/*
            echo "[$(date +" %D %T") ] delete user">>$log_file
            ls /home/$surname/
            userdel $surname

            rm -r /home/$surname
        fi
    else
        if [ $exit ]; then
            echo "[$(date +" %D %T") ] $surname his left the company, don't add again">>$log_file
            continue
        fi

        echo "[$(date +" %D %T") ] the user $surname does not exist">>$log_file
        # autput if name exists

        # user with account existing?
        if [ ! $(getent group $department) ]; then
            echo -e "[$(date +" %D %T") ] group $department not exists, \n creating..">>$log_file
            groupadd $department
        fi

        # Create account
        useradd -m -g "$user_group" -G "$department" "$surname"

        # user structure creating
        echo "[$(date +" %D %T") ] Creating directories for $surname">>$log_file
        count=0

        while (($count < 4)); do
            target_dir=/home/$surname/${home_directory_contains[$count]}
            mkdir $target_dir
            # set permissions rm-------
            chmod a-xwr $target_dir
            chmod u+rw $target_dir
            ((count++))
        done

        # is user in group?
        if id -nG "$surname" | grep -qw "$department"; then
            echo "[$(date +" %D %T") ] $surname belongs to $department">>$log_file
        else
            echo "[$(date +" %D %T") ] $surname does not belong to $department">>$log_file
            # add user to group
            usermod -G $department $surname
        fi

        # is user in company?
        if id -nG "$surname" | grep -qw "$company_group"; then
            echo "[$(date +" %D %T") ] $surname belongs to $company_group">>$log_file
        else
            echo "[$(date +" %D %T") ] $surname does not belong to $company_group">>$log_file
            # adding user to company
            usermod -G $company_group $surname
        fi

    fi

done <data.csv
