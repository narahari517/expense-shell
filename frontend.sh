#!/bin/bash

Log_folder="/var/log/expense"
Script_name=$(echo $0 | cut -d "." -f1)
Timestamp=$(date +%y-%m-%d-%H-%M-%S)
Logfile="$Log_folder/$Script_name-$Timestamp.log"
mkdir -p $Log_folder

userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

root_check(){
    if [ $userid -ne 0 ]
    then
        echo -e "$R Please run the script with root previleges $N" | tee -a $Logfile
        exit 1
    fi
}

validate(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is...$R FAILED $N" | tee -a $Logfile
    else
        echo -e "$2 is...$G SUCCESS $N" | tee -a $Logfile
    fi
}

echo "Script started running at: $(date)" | tee -a $Logfile

root_check

dnf install nginx -y &>>$Logfile
validate $? "Installing nginx"

systemctl enable nginx &>>$Logfile
validate $? "Enabling nginx"

systemctl start nginx &>>$Logfile
validate $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>>$Logfile
validate $? "Removing default website"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$Logfile
validate $? "Downloading frontend code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$Logfile
validate $? "Extracting frontend code"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf &>>$Logfile
validate $? "copied expense.conf"
systemctl restart nginx
