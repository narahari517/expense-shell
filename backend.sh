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

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Disable default nodejs"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enable nodejs:20"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "Install nodejs"

id expense &>>$LOGFILE
if [ $? -ne 0 ]
then
    echo -e "expense user doesn't exist,$Y creating $N"
    useradd expense &>>$LOGFILE
    VALIDATE $? "Creating expense user"
else
    echo -e "expense user already exists...$Y SKIPPING $N"
fi


mkdir -p /app &>>$LOGFILE
VALIDATE $? "Creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILE
VALIDATE $? "Downloading backend application code"

cd /app
rm -rf /app/* &>>$LOGFILE
unzip /tmp/backend.zip
VALIDATE $? "Extracting backend code"

npm install &>>$LOGFILE
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

#load the data before running the backend
dnf install mysql -y &>>$LOGFILE
VALIDATE $? "installing mysql client"

mysql -h mysql.nhari.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "Loading schema"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon reload"

systemctl enable backend &>>$LOGFILE
VALIDATE $? "Enable backend"

systemctl restart backend &>>$LOGFILE
VALIDATE $? "Starting backend"

