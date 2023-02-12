#!/bin/bash -i
#####################
# addRemoteMember.sh
#####################
# This script runs on the REMOTE Liberty HOST. 
# It is invoked from the createRemoteMember.sh from the CONTROLLER HOST
# The useage is: 
# addRemoteMember.sh <Liberty_Server_Name> <LibertyVersion> <LibertyServerHttpPort> <ControllerHttpsPort>"


if [[ "$#" -lt 5 ]]; then
  echo "Missing command parameters, check usage"
  echo "---------------------------------------"
  echo "Usage:" 
  echo "   addRemoteMember.sh <LibertyServerName> <LibertyVersion> <LibertyHttpPort> <Liberty_HttpsPort> <ControllerHttpsPort>"
  echo ""
  echo "example: addRemoteMember.sh testServer 22.0.0.8 9085 9445 9493"
  echo ""
  echo "---------------------------------------"
  return 1
fi

LAB_HOME=/home/techzone
LOGS=/home/techzone
LOG=$LOGS/2_addRemoteMember.log

echo "#--------------------------------------------------" | tee $LOG
echo "# Now running addRemoteMember.sh on $HOSTNAME" | tee -a $LOG
echo "#--------------------------------------------------" | tee -a $LOG

sleep 10

WLP_ROOT_DIR=/opt/IBM/staging
WLP_HOME=$WLP_ROOT_DIR/wlp
PACKAGED_PBW_SERVER_NAME="pbwServerX"
HOSTNAME=`hostname`
CONTROLLER_HOST=server0.gym.lan
LIBERTY_SERVER=$1
LIBERTY_VERSION=$2
LIBERTY_HTTP_PORT=$3
LIBERTY_HTTPS_PORT=$4
CONTROLLER_HTTPS_PORT=$5
LIBERTY_ARCHIVE="$LIBERTY_VERSION-$PACKAGED_PBW_SERVER_NAME.zip"


echo " " | tee -a $LOG
echo "# List the variables used in the script" | tee -a $LOG
echo "#----------------------------------------------------" | tee -a $LOG
echo "# Liberty Server to join the collective is: $LIBERTY_SERVER" | tee -a $LOG
echo "# Liberty Version to join the collective is: $LIBERTY_VERSION" | tee -a $LOG
echo "# Liberty Server HTTP Port: $LIBERTY_HTTP_PORT" | tee -a $LOG
echo "# host is: `hostname`" | tee -a $LOG
echo "# Liberty Archive: $LIBERTY_ARCHIVE" | tee -a $LOG
echo "# Liberty Home is: $WLP_HOME" | tee -a $LOG  
echo "# Controller Host is: $CONTROLLER_HOST" | tee -a $LOG
echo "# Controller HTTPS port is: $CONTROLLER_HTTPS_PORT" | tee -a $LOG
echo "#----------------------------------------------------" | tee -a $LOG
echo "" | tee -a $LOG


cd /home/techzone
echo "curent directory is" `pwd` 
echo "-------------------------------------------------------"


unzip_liberty_archive()
{
#Unzip the Liberty archive. Use -o option to overwrite files. 

  echo "create the $WLP_ROOT_DIR if it does not exist"

  if [ ! -d "$WLP_ROOT_DIR" ]; then
    echo "Create the $WLP_ROOT_DIR directory"
    mkdir $WLP_ROOT_DIR
  fi


  echo "" | tee -a $LOG
  echo "# unzip the Liberty archive" | tee -a $LOG
  echo "unzip -o /home/techzone/Downloads/$LIBERTY_ARCHIVE -d $WLP_ROOT_DIR" | tee -a $LOG
  echo "" | tee -a $LOG

  unzip -o /home/techzone/Downloads/$LIBERTY_ARCHIVE -d $WLP_ROOT_DIR

  echo "" 
  echo "Liberty server unpackaged in $WLP_ROOT_DIR" 
  echo ""  

  cd /home/techzone
}

apply_server_updates()
{
#The server package uses the default server nams as pbwServerX. 
#Must be changed to $SERVER_NAME that is passed in 
#The memberOverrides.xml file must be updated to specify the HTTP and HTTPS ports passed in



#Rename the serverX server dir to $SERVER_NAME passed it

echo "Rename the default packaged server name $PACKAGED_PBW_SERVER_NAME to $LIBERTY_SERVER"
mv   $WLP_HOME/usr/servers/$PACKAGED_PBW_SERVER_NAME $WLP_HOME/usr/servers/$LIBERTY_SERVER

 
#Update the Liberty server ports in the memberOverrides.xml with ports passed into script
  echo "" | tee -a $LOG
  echo "# Update the Liberty server ports in the memberOverrides.xml" | tee -a $LOG
  echo "sed -i 's/9084/'$LIBERTY_HTTP_PORT'/g' $WLP_HOME/usr/servers/$LIBERTY_SERVER/configDropins/overrides/memberOverride.xml" | tee -a $LOG
  echo "sed -i 's/9446/'$LIBERTY_HTTPS_PORT'/g' $WLP_HOME/usr/servers/$LIBERTY_SERVER/configDropins/overrides/memberOverride.xml" | tee -a $LOG
  echo "" | tee -a $LOG
  
  
  sed -i 's/9084/'$LIBERTY_HTTP_PORT'/g' $WLP_HOME/usr/servers/$LIBERTY_SERVER/configDropins/overrides/memberOverride.xml 
  sed -i 's/9446/'$LIBERTY_HTTPS_PORT'/g' $WLP_HOME/usr/servers/$LIBERTY_SERVER/configDropins/overrides/memberOverride.xml 
  echo "HTTP port is now set to $LIBERTY_HTTP_PORT in configOverrides" 
  echo "HTTPS port is now set to $LIBERTY_HTTPS_PORT in configOverrides" 
 





}



join_collective()
{
#join the Liberty server to the collective


  echo "" | tee -a $LOG
  echo "# Join the remote Liberty Server $LIBERTY_SERVER to the collective" | tee -a $LOG
  echo " "
  
  echo "$WLP_HOME/bin/collective join $LIBERTY_SERVER --host=$CONTROLLER_HOST --port=$CONTROLLER_HTTPS_PORT --user=admin --password=admin --keystorePassword=memberKSPassword --createConfigFile=$WLP_HOME/usr/servers/$LIBERTY_SERVER/controller.xml" | tee -a $LOG
  echo " " | tee -a $LOG

  echo "---------------------------------------------------------------------------" 
  echo "Reply 'y' when prompted to accept the certificate chain, (collective join)." 
  echo "---------------------------------------------------------------------------"   

  sleep 10


  $WLP_HOME/bin/collective join $LIBERTY_SERVER --host=$CONTROLLER_HOST --port=$CONTROLLER_HTTPS_PORT --user=admin --password=admin --keystorePassword=memberKSPassword --createConfigFile=$WLP_HOME/usr/servers/$LIBERTY_SERVER/controller.xml

# echo "return code from collective join command: $? "

  if [[ $? != 0 ]]; then
     echo "#ERROR Failed to join the remote Liberty server $LIBERTY_SERVER to the collective. See the error message that was returned!" | tee -a $LOG
     
     #cleanup the Remote Liberty Server directory
     delete_liberty_server $LIBERTY_SERVER  
         
     exit 1
  fi 

  echo "Liberty Server $LIBERTY_SERVER joined the collective and is visible in the Admin Center."  
}


delete_liberty_server()
{

#Delete the liberty server directory

  if [ -d "$WLP_HOME/usr/servers/$LIBERTY_SERVER" ]; then
    echo "" | tee -a $LOG
    echo "# Delete the server directory"  | tee -a $LOG
    echo "# rm -rf $WLP_HOME/usr/servers/$LIBERTY_SERVER" | tee -a $LOG
    echo "" | tee -a $LOG

    rm -rf $WLP_HOME/usr/servers/$LIBERTY_SERVER | tee -a $LOG

    echo "$WLP_HOME/usr/servers/$LIBERTY_SERVER directory has been removed"  
    echo "" 
  fi
}



setup_firewall_ports()
{

#The Application HTTP ports need to be opened
echo "" | tee -a $LOG
echo "# The Application HTTP port $LIBERTY_HTTP_PORT needs to be open for the HTTP server to route traffic to the Liberty server." | tee -a $LOG
echo "" | tee -a $LOG

#open application HTTP port, if not found
  appHttpPortFound=$(sudo firewall-cmd --list-ports | grep $LIBERTY_HTTP_PORT/tcp | wc -l)

  if [[ "$appHttpPortFound" -lt 1 ]]; then
    echo "Need to open port $LIBERTY_HTTP_PORT, the application HTTP port"
    sudo firewall-cmd --permanent --zone=public --add-port=$LIBERTY_HTTP_PORT/tcp 
    sleep 7
  fi  
    
#reload the firewall settings
  echo "reloading the firewall rules!" 
  sudo firewall-cmd --reload 
  
  echo "WAITING for Firewall rules to reload............ " 
  echo "" | tee -a $LOG
  sleep 15
  

#List the ports 
  echo "" | tee -a $LOG
  echo "# List the opened ports" | tee -a $LOG
  echo "" 
  echo "# $(sudo firewall-cmd --list-ports)" | tee -a $LOG
  
  echo "" | tee -a $LOG
  echo "#INFORMATION ONLY!!! The ports were opened by using the following commands on Host $HOSTNAME"  | tee -a $LOG
  echo "" | tee -a $LOG
  echo "#----------------------------------------------------------------------------" | tee -a $LOG
  echo "# Note: The Liberty applications HTTP port must be opened to run through an HTTP Server" | tee -a $LOG 
  echo "# firewall-cmd --list-ports" | tee -a $LOG 
  echo "# firewall-cmd --permanent --zone=public --add-port=$LIBERTY_HTTP_PORT/tcp" | tee -a $LOG
  echo "# firewall-cmd --reload" | tee -a $LOG
  echo "#----------------------------------------------------------------------------" | tee -a $LOG
 echo "" | tee -a $LOG
 
#verify the ports are opened. Exit of they are not opened.  
 
#Get updated state... 
   appHttpPortFound=$(sudo firewall-cmd --list-ports | grep $LIBERTY_HTTP_PORT/tcp | wc -l) 
   

  if [[ "$appHttpPortFound" -gt "0" ]]; then
    echo "----------------------------------------------------------------------------" 
    echo "Required port $LIBERTY_HTTP_PORT for the Liberty Appliction Server HTTP port is opened" 
    echo "Script will continue!" 
    echo "----------------------------------------------------------------------------" 
    sleep 7
  else 
    echo "Required port $LIBERTY_HTTP_PORT for the Liberty Appliction Server HTTP port NOT opened"
    echo "Exiting!" 
    echo ""
    echo "open the required ports using the following commands on the Liberty Controller VM." 
    echo "Then rerun the script."  
    echo "----------------------------------------------------------------------------" 
    echo "sudo firewall-cmd --permanent --zone=public --add-port=$LIBERTY_HTTP_PORT/tcp" 
    echo "----------------------------------------------------------------------------" 
  
    exit 1
  fi  
  
}



#MAIN PROGRAM

echo "============================="
echo "Running 'addRemoteMember.sh'"
echo "============================="
  
  unzip_liberty_archive
  apply_server_updates
  join_collective
  setup_firewall_ports


echo "# End of addRemoteMember.sh script." | tee -a $LOG
