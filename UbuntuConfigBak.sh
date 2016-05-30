#!/bin/bash
# Backup and restore Ubuntu configuration files
# Version 0.2
# 2016-05-29
# David Loibl

echo
echo "======================== Ubuntu Config Backup v0.1========================"
echo
echo "This script will backup or restore Ubuntu user configuration files."
echo "What do you want to do?"

OPTIONS="backup restore exit"
select opt in $OPTIONS; do
  if [ "$opt" = "backup" ]; then
    # Start BACKUP 
    echo "Creating backup of Ubuntu configuration for user $USER"
    echo "Please enter directory to save the backup files:"
    
    # Choose folder for backup ..
    proceed=false
    while [ $proceed = false ]; do
      read BACKUPPATH
      if [ "$BACKUPPATH" = "" ]; then
        echo "No directory specified. Using ~/ConfigBak/"
        BACKUPPATH="/home/$USER/ConfigBak"   
      fi
      if [ ! -d "$BACKUPPATH" ]; then
        echo "Directory $BACKUPPATH does not exist. Do you want to create it?"
        DIROPTIONS="yes no"
        select diropt in $DIROPTIONS; do
          if [ "$diropt" = "yes" ]; then
            echo "Creating folder $BACKUPPATH"
            mkdir -p $BACKUPPATH
            proceed=true
            break
          elif [ "$diropt" = "no" ]; then
            echo
	    echo "Please specify another directory."
          fi
        done    
      else
        echo "Using exisitng directory $BACKUPPATH for backup."
        proceed=true        
      fi
    done
    
    # Start backup
    echo 
    echo "Starting Backup"
    echo
    echo "Step 1: Packackes .."
    dpkg --get-selections > $BACKUPPATH/Package.list
    echo
    echo "Step 2: Sources .."
    sudo cp -R /etc/apt/sources.list* $BACKUPPATH/
    echo
    echo "Step 3: Keys .."
    sudo apt-key exportall > $BACKUPPATH/Repo.keys    

    echo
    echo "Step 4 (optional): Do you also want to backup your home directory?"
    BAKHOMEDIR="yes no"
    select bakhomedir in $BAKHOMEDIR; do
      if [ "$bakhomedir" = "yes" ]; then
        rsync -a --progress /home/$USER $BACKUPPATH/UserProfile
        break
      else
	break
      fi
    done 
    
    echo done
    exit
  
  elif [ "$opt" = "restore" ]; then
    # Restore Backup
    echo "Restoring backup of Ubuntu configuration for user $USER"
    echo "Please enter directory where your backup files are located:"
    echo "(empty will try \"ConfigBak\" in your home directory)"

    read BACKUPPATH
    if [ -n "$BACKUPPATH" ]; then
      echo "No directory specified. Assuming ~/ConfigBak/"
      BACKUPPATH="home/$USER/ConfigBak"   
    fi

    if [ ! -d "$BACKUPPATH" ]; then
      echo
      echo "Directory does not exist."
    fi    

    if [ -d "$BACKUPPATH/UserProfile" ]; then
      echo
      echo "Home directory backup data found. Do you want to restore it?"
      echo "CAUTION: this will overwrite existing data in the Home directory"
      RESTOREHOME="yes no"
      select restorehome in $RESTOREHOME; do
        if [ "$restorehome" = "yes" ]; then
	  rsync --progress $BACKUPPATH/UserProfile /home/$USER
	  break
        fi
      done
    fi



    sudo apt-key add $BACKUPPATH/Repo.keys
    sudo cp -R $BACKUPPATH/sources.list* /etc/apt/
    sudo apt-get update
    sudo apt-get install dselect
    sudo dpkg --set-selections < $BACKUPPATH/Package.list
    sudo dselect
  
  elif [ "$opt" = "exit" ]; then
    exit
  else
    echo "Bad option"
    exit
  fi
done




