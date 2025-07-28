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
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
    echo "User roboshop already exists  $Y SKIPPING $N"
fi

rm -rf /app &>>$LOG_FILE
mkdir /app &>>$LOG_FILE
curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading the cart.zip"

cd /app &>>$LOG_FILE
unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "unzipping the files"
npm install &>>$LOG_FILE
VALIDATE $? "installing dependencies"
cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
VALIDATE $? "copying the cart service"
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reloading the cart service"
systemctl enable cart &>>$LOG_FILE
VALIDATE $? "enabling cart"
systemctl start cart &>>$LOG_FILE
VALIDATE $? "starting the cart service"

