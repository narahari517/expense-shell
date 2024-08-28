#!/bin/bash

Log_folder="/var/log/expense"
Script_name=$(echo $0 | cut -d "." -f1)
Timestamp=$(date +%y-%m-%d-%H-%M-%S)
logfile="$Log_folder/$Script_name-$Timestamp"
mkdir -p $Log_folder

userid=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

root_check(){
    if [ $userid -ne 0 ]
    then
        echo -e "$R Please run the script with root previleges $N" | tee -a $logfile
        exit 1
    fi
}

validate(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is $R FAILED $N" | tee -a $logfile
        exit 1
    else
        echo -e "$2 is $G SUCCESS $N" | tee -a $logfile
    fi
}

echo "Script started running at: $(date)" | tee -a $logfile

root_check

dnf list installed mysql
if [ $? -ne 0 ]
then
    echo "mysql is not installed, doing it now" tee -a $logfile
    dnf install mysql-server -y &>>$logfile
    validate $? "Installing mysql server" tee -a $logfile
else
    echo -e "mysql is already installed, $Y SKIPPING $N" tee -a $logfile
fi

systemctl enable mysqld &>>$logfile
validate $? "Enabling mysql server"

systemctl start mysqld &>>$logfile
validate $? "Starting mysql server"

mysql -h mysql.nhari.online -u root -pExpenseApp@1 -e 'show databases;' &>>$logfile
if [ $? -ne 0 ]
then
    echo "mysql root password is not setup, setting now" &>>$logfile
    mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$logfile
    validate $? "Setting up mysql root password" | tee -a $logfile
else
    echo -e "mysql root password is already setup, $Y SKIPPING $N" | tee -a $logfile
fi

