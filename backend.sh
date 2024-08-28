#!/bin/bash

userid=$(id -u)

Log_folder="/var/log/expense"
script_name=$(echo $0 | cut -d "." -f1)
Timestamp=$(date +%y-%m-%d-%H-%M-%S)
logfile="$Log_folder/$script_name-$Timestamp.log"
mkdir -p $Log_folder

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

root_check(){
    if [ $userid -ne 0 ]
    then
        echo -e "$R Please run the script with root privileges $N" | tee -a $logfile
        exit 1
    fi
}

validate(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is...$R FAILED $N" | tee -a $logfile
        exit 1
    else
        echo -e "$2 is...$G SUCCESS $N" | tee -a $logfile
    fi
}

echo "Script started running at: $(date)" | tee -a $logfile

root_check

dnf module disable nodejs -y &>>$logfile
validate $? "Disable default nodejs"

dnf module enable nodejs:20 -y &>>$logfile
validate $? "Enable nodejs:20"

dnf install nodejs -y &>>$logfile
validate $? "Installing nodejs:20"

useradd expense &>>$logfile
validate $? "Creating expense user"

