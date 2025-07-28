#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="/$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD
mkdir -p $LOGS_FOLDER
echo "script started executing at $(date)"| tee -a $LOG_FILE
if [ "$USERID" -ne 0 ]
then   
    echo -e "$R you are not running with root access, please run with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo -e "$G you are running with root access $N" | tee -a $LOG_FILE
fi
VALIDATE(){
if [ "$1" -eq 0 ]
then
    echo -e "$2 is $G success $N" | tee -a $LOG_FILE
else
    echo -e "$2 is $R failure $N" | tee -a $LOG_FILE
    exit 1
fi
}
cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "copying the repo file"
dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "installing the rabbitmq server"
systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "enabling rabbitmq server"
systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "starting rabbitmq server"
rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
VALIDATE $? "adding the user"
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
VALIDATE $? "setting the permissions to the user"

