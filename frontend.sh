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
dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "disabling nginx"
dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enabling nginx 24 version"
dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installing nginx"
systemctl enable nginx &>>$LOG_FILE
# VALIDATE $? "enabling nginx service"
systemctl start nginx &>>$LOG_FILE
VALIDATE $? "starting nginx"
rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "removing the default files"
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading the frontend.zip file"
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzipping the files"
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "copying the nginx configuration file to the location"
systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "restarting the nginx"


