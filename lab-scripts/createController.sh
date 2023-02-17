######################
#  createController.sh 
######################

## No input parameters required to run this script. We use default ports and names in script variables. 

LAB_HOME=/home/techzone
WORK_DIR="/home/techzone/lab-work"
LIBERTY_ROOT_DIR=$WORK_DIR/liberty-controller
LAB_FILES=$LAB_HOME/liberty_admin_pot
LOGS=$WORK_DIR/logs
LOG=$LOGS/0_createController.log
SCRIPT_ARTIFACTS=$LAB_FILES/lab-scripts/scriptArtifacts
WLP_HOME=$LIBERTY_ROOT_DIR/wlp


HOSTNAME=`hostname`
echo $HOSTNAME

CONTROLLER_NAME="CollectiveController"

#HTTP_PORT=$(echo $2 | cut -f1 -d:)
#HTTPS_PORT=$(echo $2 | cut -f2 -d:)
#echo "http port: $HTTP_PORT"
#echo "https port: $HTTPS_PORT"

#HTTPS_PORT=$1
#echo "https port: $HTTPS_PORT"


HTTP_PORT="9091"
HTTPS_PORT="9491"



#create the WORK_DIR for the labs
if [ ! -d "$WORK_DIR" ]; then
     mkdir $WORK_DIR ;
     echo "Create the Working directory if it does not exist: $WORK_DIR"
fi 


if [ ! -d "$LOGS" ]; then
     mkdir $LOGS ;
     echo "Create Logs Directory: $LOGS"
fi

if [ -d "$LOGS" ]; then
     rm -f $LOGS/0*.log ;
     rm -f $LOGS/1*.log ;
     rm -f $LOGS/2*.log ;
     rm -f $LOGS/3*.log ;
     rm -f $LOGS/4*.log ;
#     echo "remove the logs pertaining to the colective in directory: $LOGS"
fi 



echo "#----------------------------------" | tee $LOG
echo "# Now running createController.sh" | tee -a $LOG
echo "#----------------------------------" | tee -a $LOG


echo "" | tee -a $LOG
echo "# Variables used in the script" | tee -a $LOG
echo "#-------------------------------------------------------------" | tee -a $LOG
echo "# Lab Home: $LAB_HOME" | tee -a $LOG
echo "# Lab Files Directory: $LAB_FILES" | tee -a $LOG
echo "# Liberty Home directory: $WLP_HOME" | tee -a $LOG
echo "# Controller Hostname: $HOSTNAME" | tee -a $LOG
echo "# Name of Controller server: $CONTROLLER_NAME" | tee -a $LOG
echo "# Controller HTTP Port: $HTTP_PORT" | tee -a $LOG
echo "# Controller HTTPS Port: $HTTPS_PORT" | tee -a $LOG
echo "#--------------------------------------------------------------" | tee -a $LOG
echo "" | tee -a $LOG

sleep 7


install_liberty_controller()
{
#check if Liberty is installed in the $LAB_HOME 
#If not, install Liberty from the archive in Stdent/LabFiles, into LAB_HOME


#Create the $LIBERTY_ROOT, if it does not already exist

echo "" | tee -a $LOG
echo "# create the Librty root directory, if it does not exist" | tee -a $LOG  
echo "mkdir $LIBERTY_ROOT_DIR" | tee -a $LOG
echo "" | tee -a $LOG



if [ ! -d "$LIBERTY_ROOT_DIR" ]; then
    echo "Create the $LIBERTY_ROOT_DIR directory"
    mkdir $LIBERTY_ROOT_DIR
fi

echo "WLP_HOME: $WLP_HOME"
sleep 7


#Install Liberty for the collective controller using the archive method, if Liberty is not already installed.

echo "" | tee -a $LOG
echo "# Install Liberty for the Collective Controller, if its not already installed" | tee -a $LOG  
echo "unzip -o ~/Student/LabFiles/controllerArchive.zip -d $LIBERTY_ROOT_DIR" | tee -a $LOG
echo "" | tee -a $LOG


if [ ! -d "$WLP_HOME" ]; then
    echo "Unzip Liberty to the $LIBERTY_ROOT directory"
    unzip -o ~/Student/LabFiles/controllerArchive.zip -d $LIBERTY_ROOT_DIR
fi


}



create_collective()
{

#Stop the Liberty Controller server, if it is running
echo "" | tee -a $LOG
echo "# stop the Liberty Controller, if it is running" | tee -a $LOG
echo "$WLP_HOME/bin/server stop $CONTROLLER_NAME" | tee -a $LOG
echo "" | tee -a $LOG
echo "" | tee -a $LOG

if [ -d "$WLP_HOME/usr/servers/$CONTROLLER_NAME" ]; then
  $WLP_HOME/bin/server stop $CONTROLLER_NAME ;
  echo "$CONTROLLER_NAME stopped" 
  sleep 5

#Cleanup the Liberty Server directory  
  echo "" | tee -a $LOG
  echo "# Ensure the Liberty server directory is clean" | tee -a $LOG
  echo "rm -rf $WLP_HOME/usr/servers/$CONTROLLER_NAME" | tee -a $LOG
  echo "rm -rf $WLP_HOME/usr/servers/*" | tee -a $LOG
  echo "" | tee -a $LOG
  
  rm -rf $WLP_HOME/usr/servers/$CONTROLLER_NAME ;
  rm -rf $WLP_HOME/usr/servers/* ;
  echo "controller $CONTROLLER_NAME removed" 
  echo "" | tee -a $LOG
  echo "$CONTROLLER_NAME directory structure removed" 
  sleep 5
fi

#Create the collective controller server
echo "" | tee -a $LOG
echo "# create the $CONTROLLER_MAME Liberty server" | tee -a $LOG
echo "$WLP_HOME/bin/server create $CONTROLLER_NAME" | tee -a $LOG
echo "" | tee -a $LOG

$WLP_HOME/bin/server create $CONTROLLER_NAME

 if [[ $? != 0 ]]; then
   echo "Failed to create the Liberty Server: $CONTROLLER_NAME. See the error message that was returned!"
   exit $?
  fi 

echo "Controller $CONTROLLER_NAME created" 


#Create the collective
echo "" | tee -a $LOG
echo "# create the Liberty Collective" | tee -a $LOG
echo "$WLP_HOME/bin/collective create $CONTROLLER_NAME --keystorePassword=passw0rd --createConfigfile=$WLP_HOME/usr/servers/$CONTROLLER_NAME/controller.xml" | tee -a $LOG
echo "" | tee -a $LOG

$WLP_HOME/bin/collective create $CONTROLLER_NAME --keystorePassword=passw0rd --createConfigfile=$WLP_HOME/usr/servers/$CONTROLLER_NAME/controller.xml

if [[ $? != 0 ]]; then
   echo "Failed to create the Liberty Collective: See the error message that was returned!"
   exit $?
  fi 

echo "" 
echo "Collective created.." 
echo "" 
echo "controller.xml generated in $WLP_HOME/usr/servers/$CONTROLLER_NAME" 
echo ""


#Create the configDropins/overrides directory
echo "" | tee -a $LOG
echo "# create the configDropins/overrides directory" | tee -a $LOG
echo "mkdir $WLP_HOME/usr/servers/$CONTROLLER_NAME/configDropins" | tee -a $LOG
echo "mkdir /$WLP_HOME/usr/servers/$CONTROLLER_NAME/configDropins/overrides" | tee -a $LOG
echo "" | tee -a $LOG

mkdir $WLP_HOME/usr/servers/$CONTROLLER_NAME/configDropins 
mkdir /$WLP_HOME/usr/servers/$CONTROLLER_NAME/configDropins/overrides 
echo "" 

echo "$WLP_HOME/usr/servers/$CONTROLLER_NAME/configDropins/overrides directory created" 
echo "" 

#Copy the controllerOverride.xml into the configDropins/overrides directory
echo "" | tee -a $LOG
echo "# copy the controllerOverride.xml file to the configDropis/overrides directory" | tee -a $LOG
echo "cp $SCRIPT_ARTIFACTS/controllerOverride.xml $WLP_HOME/usr/servers/$CONTROLLER_NAME/configDropins/overrides" | tee -a $LOG
echo "" | tee -a $LOG


cp $SCRIPT_ARTIFACTS/controllerOverride.xml $WLP_HOME/usr/servers/$CONTROLLER_NAME/configDropins/overrides

echo "$SCRIPT_ARTIFACTS/controllerOverride.xml copied to $WLP_HOME/usr/servers/$CONTROLLER_NAME/configDropins/overrides" 


#Override the Controller ports in the configDropins with the ports variables above 

  echo "" | tee -a $LOG
  echo "# Update the Controller Liberty server ports in the controllerOverrides.xml" | tee -a $LOG
  echo "sed -i 's/9090/'$HTTP_PORT'/g' $WLP_HOME/usr/servers/$CONTROLLER_NAME/configDropins/overrides/controllerOverride.xml" | tee -a $LOG
  echo "" | tee -a $LOG
  echo "sed -i 's/9493/'$HTTPS_PORT'/g' $WLP_HOME/usr/servers/$CONTROLLER_NAME/configDropins/overrides/controllerOverride.xml" | tee -a $LOG
  echo "" | tee -a $LOG
  
  
  sed -i 's/9090/'$HTTP_PORT'/g' $WLP_HOME/usr/servers/$CONTROLLER_NAME/configDropins/overrides/controllerOverride.xml 
  sed -i 's/9493/'$HTTPS_PORT'/g' $WLP_HOME/usr/servers/$CONTROLLER_NAME/configDropins/overrides/controllerOverride.xml 
  echo "HTTP port is now set to $HTTP_PORT in configOverrides" 
  echo "HTTPS port is now set to $HTTPS_PORT in configOverrides" 






#Start the Liberty Collective Controller server
echo "" | tee -a $LOG
echo "# Start the Controller $CONTROLLER_NAME" | tee -a $LOG
echo "$WLP_HOME/bin/server start $CONTROLLER_NAME" | tee -a $LOG
echo "" | tee -a $LOG


$WLP_HOME/bin/server start $CONTROLLER_NAME

sleep 5

if [[ $? != 0 ]]; then
   echo "The Liberty Controller server $CONTROLLER_NAME failed to start: See the error message that was returned!"
   exit $?
  fi 
  
echo "$CONTROLLER_NAME server started successfully." 
echo ""


#print location of log files 
 
echo ""     
echo "---------------------------------------------------------------"
echo ""
echo "Review the log file. It shows the commands the script executed."
echo "" 
echo "  $LOG"
echo ""
echo "---------------------------------------------------------------"
echo ""   


#Print the URL of the Liberty Admin Center
echo "# --> Admin Center URL: https://server0.gym.lan:$HTTPS_PORT/adminCenter" | tee -a $LOG

echo "" | tee -a $LOG
echo "# End of createController.sh script." | tee -a $LOG
echo "" | tee -a $LOG


}


#MAIN PROGRAM

echo "============================="
echo "Running 'createController.sh'"
echo "============================="

  install_liberty_controller
  
  create_collective
 

 
      
  
 
 