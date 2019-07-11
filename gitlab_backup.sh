#!/bin/bash
#
# GitLab backup script v1.0
#

# Backup main path
BACKUP_PATH="/mnt/"

# Change to copy if the data changes while backing up
# Can be "copy" or "tar"
BACKUP_MODE="tar"

# Log path
LOG_PATH="/var/log/gitlab_backup.log"

#####################################################
CUR_DATE=`date "+%Y_%m_%d_%H_%M_%S"`

echo "$(date '+%Y_%m_%d_%H_%M_%S') Starting backup..." >> $LOG_PATH
function create_backup_dir(){
	mkdir ${BACKUP_PATH}/GitLab_Backup_${CUR_DATE}
	echo "$(date '+%Y_%m_%d_%H_%M_%S') Backup directory created under ${BACKUP_PATH}/GitLab_Backup_${CUR_DATE}" >> $LOG_PATH
}

function run_backup(){
	GITLAB_BACKUP_PATH=`grep 'backup_path' /etc/gitlab/gitlab.rb | grep -v manage | cut -d "=" -f2 | cut -d '"' -f2`
	echo "$(date '+%Y_%m_%d_%H_%M_%S') Running gitlab-rake ..." >> $LOG_PATH
	gitlab-rake gitlab:backup:create STRATEGY=${BACKUP_MODE}

	if [ $? -eq 0 ]
	then
		echo "$(date '+%Y_%m_%d_%H_%M_%S') gitlab-rake is done" >> $LOG_PATH
		LAST_BACKUP=`ls -ltr ${GITLAB_BACKUP_PATH} | awk '{print $9}' | tail -n 1`
		cp ${GITLAB_BACKUP_PATH}/${LAST_BACKUP} ${BACKUP_PATH}/GitLab_Backup_${CUR_DATE}
	else
		echo "$(date '+%Y_%m_%d_%H_%M_%S') [WARNING] Backup failed" >> $LOG_PATH
		echo "[WARNING] Backup failed"
		exit 1
	fi
}

function run_config_backup(){
	echo "$(date '+%Y_%m_%d_%H_%M_%S') Running configuration backup..." >> $LOG_PATH
	tar cf ${BACKUP_PATH}/GitLab_Backup_${CUR_DATE}/GitLab_Config.tar /etc/gitlab/
}

function run_path_archive(){
	echo "$(date '+%Y_%m_%d_%H_%M_%S') Creating backup archive..." >> $LOG_PATH
	tar cf ${BACKUP_PATH}/GitLab_Backup_${CUR_DATE}.tar ${BACKUP_PATH}/GitLab_Backup_${CUR_DATE}
}

function run_remove_backup_dir(){
	rm -r ${BACKUP_PATH}/GitLab_Backup_${CUR_DATE}
}

create_backup_dir
run_backup
run_config_backup
run_path_archive
run_remove_backup_dir

echo "$(date '+%Y_%m_%d_%H_%M_%S') Backup finished" >> $LOG_PATH
