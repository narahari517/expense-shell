#!/bin/bash

LOG_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%y-%m-%d-%H-%M-%S)
LOGFILE="$LOG_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOG_FOLDER

userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

ROOT_CHECK(){
    if [ $userid -ne 0 ]
    then
        echo -e "$R Please run this script with root previleges $N" | tee -a $LOGFILE
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is...$R FAILED $N" | tee -a $LOGFILE
        exit 1
    else
        echo -e "$2 is...$G SUCCESS $N" | tee -a $LOGFILE
    fi
}

echo "Script started running at: $(date)" | tee -a $LOGFILE

ROOT_CHECK

dnf install nginx -y &>>$LOGFILE
VALIDATE $? "Installing nginx"

systemctl enable nginx &>>$LOGFILE
VALIDATE $? "Enable nginx"

systemctl start nginx &>>$LOGFILE
VALIDATE $? "Start nginx"

rm -rf /usr/share/nginx/html/* &>>$LOGFILE
VALIDATE $? "Deleting default website"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOGFILE
VALIDATE $? "Downloading frontend application code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOGFILE
VALIDATE $? "Extracting the code"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "copied expense conf"

systemctl restart nginx &>>$LOGFILE
VALIDATE $? "starting nginx"
