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
dnf install maven -y
VALIDATE $? "installing maven " &>>$LOG_FILE
id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
    echo "user already exists"
fi
rm -rf /app &>>$LOG_FILE
mkdir /app &>>$LOG_FILE
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading the shipping"
cd /app &>>$LOG_FILE
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzipping the shipping"
cd /app 
mvn clean package &>>$LOG_FILE
VALIDATE $? "cleaning package"
mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE "moving the file"
cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "copying the shipping service file"
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon-reload the shipping service"
systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "enabling shipping service"
systemctl start shipping &>>$LOG_FILE
VALIDATE $? "starting shipping service"
dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "installing my sql"
mysql -h mysql.prasannadevops.online -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
VALIDATE $? "loading the schema"
mysql -h mysql.prasannadevops.online -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
VALIDATE $? "creating user"
mysql -h mysql.prasannadevops.online -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
VALIDATE $? "loading the master data"
systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "restarting shipping service"
