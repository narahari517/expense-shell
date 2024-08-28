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

id expense &>>$logfile
if [ $? -ne 0 ]
then
    echo -e "expense user is not exist, $G creating now $N" | tee -a $logfile
    useradd expense &>>$logfile
    validate $? "Creating expense user" | tee -a $logfile
else
    echo -e "expense user is already created...$Y SKIPPING $N" | tee -a $logfile
fi

mkdir -p /app &>>$logfile
validate $? "Creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$logfile
validate $? "Downloading backend application code"

cd /app
rm -rf /app/*
unzip /tmp/backend.zip &>>$logfile
validate $? "Extracting backend application code" | tee -a $logfile

npm install &>>$logfile
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

#load the data before running backend

dnf install mysql -y &>>$logfile
validate $? "Installing mysql client"

mysql -h mysql.nhari.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$logfile
validate $? "schema loading"

systemctl daemon-reload &>>$logfile
validate $? "daemon reload"

systemctl enable backend &>>$logfile
validate $? "enable backend"

systemctl restart backend &>>$logfile
validate $? "restart backend"