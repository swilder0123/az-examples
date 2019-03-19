# Be already logged in, or put a valid login command below

# must set the following values to match a current deployment
RESOURCE_GROUP="cpgateway"
GATEWAY_NAME="cpgateway"
ACTION_GROUP="Application Gateway Administrators"

HTTP_STATUS="4xx"   #must correspond to a class of HTTP returns, i.e. 3xx, 4xx, 5xx

# set a unique name for this alert
ALERT_NAME="Client_"
ALERT_NAME+=$HTTP_STATUS
ALERT_NAME+="_errors_$RANDOM"

# Query for the existence of the gateway resource
QUERYSTR="[?name=='"
QUERYSTR+=$GATEWAY_NAME
QUERYSTR+="'].id"
# echo  "Querying for the gateway resource..."
GATEWAY_RESOURCE=$(az resource list -g $RESOURCE_GROUP --resource-type Microsoft.Network/applicationGateways --query "$QUERYSTR" -o tsv)
# echo "$GATEWAY_RESOURCE located"

# If the named  Application Gateway doesn't exist, we cannot proceed.
if [ -z "$GATEWAY_RESOURCE" ]
  then
     echo "ERROR: The gateway resource was not found."
     exit 1
fi

# Query for the existence of the action group
QUERYSTR="[?name=='"
QUERYSTR+=$ACTION_GROUP
QUERYSTR+="'].id"
echo "Querying for the action group resource with $QUERYSTR"
ACTION_GROUP_RESOURCE=$(az resource list -g $RESOURCE_GROUP --resource-type Microsoft.Insights/actionGroups --query "$QUERYSTR" -o tsv)
echo "$ACTION_GROUP_RESOURCE located"

if [ -z "$ACTION_GROUP_RESOURCE" ] 
  then
    echo "ERROR: The action group resource was not found."
    exit 1
fi

# choose a threshold value (# of occurrences) over a timespan (EVAL_WINDOW) evaluated at EVAL_FREQUENCY
THRESHOLD=10
EVAL_FREQUENCY=1m
EVAL_WINDOW=5m

# create the alert, which will be deployed in the RG named above.
echo  "az monitor metrics alert create"
echo  "   --name $ALERT_NAME "
echo  "    --description '$ALERT_NAME exceeds $THRESHOLD over $EVAL_WINDOW'"  
echo  "    --resource-group $RESOURCE_GROUP "
echo  "    --scopes $GATEWAY_RESOURCE "
echo  "    --condition 'total ResponseStatus >= $THRESHOLD where HttpStatusGroup includes $HTTP_STATUS'" 
echo  "    --evaluation-frequency $EVAL_FREQUENCY "
echo  "    --window-size $EVAL_WINDOW "
echo  "    --action $ACTION_GROUP_RESOURCE"

az monitor metrics alert create  \
    --name "$ALERT_NAME"  \
    --description "$ALERT_NAME exceeds $THRESHOLD over $EVAL_WINDOW"  \
    --resource-group "$RESOURCE_GROUP"  \
    --scopes "$GATEWAY_RESOURCE"  \
    --condition "total ResponseStatus >= $THRESHOLD where HttpStatusGroup includes $HTTP_STATUS"  \
    --evaluation-frequency $EVAL_FREQUENCY  \
    --window-size $EVAL_WINDOW  \
    --action "$ACTION_GROUP_RESOURCE"



