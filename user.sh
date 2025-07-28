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
VALIDATE $? "disabling nodejs"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs"
id roboshop
if [ $? -ne 0]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
    echo "User roboshop already exists  $Y SKIPPING $N"
fi

rm -rf /app
mkdir /app 
curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading the user.zip"

cd /app 
unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "unzipping the files"
npm install &>>$LOG_FILE
VALIDATE $? "installing dependencies"
cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reloading the user service"
systemctl enable user &>>$LOG_FILE
VALIDATE $? "enabling user"
systemctl start user &>>$LOG_FILE
VALIDATE $? "starting the user service"

