#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="/$LOGS_FOLDER/$SCRIPT_NAME.log"
mkdir -p $LOGS_FOLDER
echo "script started executing at $(date)"| tee -a $LOG_FILE
if ["$USERID" -ne 0]
then   
    echo "$R you are not running with root access, please run with root access $N" | tee -a $LOG_FILE
else
    echo "$G you are running with root access $N" | tee -a $LOG_FILE
fi
VALIDATE(){
if ["$1" -eq 0]
then
    echo "$2 is $G success $N"
else
    echo "$2 is $R failure $N"
    exit 1
}
fi
cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "cppying the repo file"
dnf install mongodb-org -y 
VALIDATE $? "installing mongodb"
systemctl enable mongod 
VALIDATE $? "enabling mongodb"
systemctl start mongod 
VALIDATE $? "starting mongodb"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongo.conf
VALIDATE $? "editing mongo.conf file"
systemctl restart mongod
validate $? "restarting mongodb"
