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
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "diabling nodejs"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs"
# useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
# VALIDATE $? "creating roboshop user"
mkdir /app 
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading the catalogue.zip"
rm -rf /app/*
cd /app 
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzipping the files"
npm install &>>$LOG_FILE
VALIDATE $? "installing dependencies"
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reloading the service"
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "enabling catalogue"
systemctl start catalogue&>>$LOG_FILE
VALIDATE $? "starting the catalogue service"
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "copying the mongo repo file"
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "installing the mongodb client"
mongosh --host mongodb.prasannadevops.online </app/db/master-data.js
VALIDATE $? "loading data into mongodb"
