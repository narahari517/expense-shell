#!/bin/bash

Logs_folder="/var/log/expense"
Script_name=$(echo $0 | cut -d "." -f1)
Timestamp=$(date +%Y-%m-%d-%H-%M-%S)
Logfile="$Logs_folder/$Script_name-$Timestamp.log"
mkdir -p $Logs_folder

userid=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

root_check(){
    if [ $userid -ne 0 ]
    then
        echo -e "$R Please run the script with root privileges $N" | tee -a $Logfile
        exit 1
    fi
}

validate(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is $R FAILED $N" | tee -a $Logfile
        exit 1
    else
        echo -e "$2 is $G SUCCESS $N" | tee -a $Logfile
    fi
}

echo "Script started executing at: $(date)" | tee -a $Logfile
root_check

dnf install mysql-server -y &>>$Logfile
validate $? "Installing MySQL server"

systemctl enable mysqld &>>$Logfile
validate $? "Enabling MySQL server"

systemctl start mysqld &>>$Logfile
validate $? "Starting MySQL server"
mysql -h mysql.nhari.online -u root -pExpenseApp@1 &>>$Logfile -e 'show databases;' &>>$Logfile
if [ $? -ne 0 ]
then
    echo "mysql root password is not setup, setting now." | tee -a $Logfile
    mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$Logfile
    validate $? "MySQL root password setup"
else
    echo -e "mysql root password is already setup....$Y SKIPPING $N" | tee -a $Logfile
fi
