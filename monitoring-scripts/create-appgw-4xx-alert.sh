#  Be already logged in, or put a valid login command below
# az login...

#  Get the default subscription or look up one by name...
SUBSCRIPTION_ID=$(az account list --query "[?isDefault].{Id:id} -o tsv)"
#SUBSCRIPTION_ID=$(az account list --query "[?SubscriptionName==<Your subscription name here>].{Id:id} -o tsv)"
#SUBSCRIPTION_ID=your-subid-here

# must set the following values to match a current deployment
RESOURCE_GROUP="cpgateway"
GATEWAY_NAME="cpgateway"

HTTP_STATUS="4xx"   #must correspond to a class of HTTP returns, i.e. 3xx, 4xx, 5xx

# set a unique name for this query
ALERT_NAME="Client_"$HTTP_STATUS"_errors_$($RANDOM)"   #this value must be unique for every invocation of this script

GATEWAY_RESOURCE=$(az resource list -g cpgateway --resource-type Microsoft.Network/applicationGateways --query "[?name=='cpgateway'].id" -o tsv)
#GATEWAY_RESOURCE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/applicationGateways/$GATEWAY_NAME"

if [-z $GATEWAY_RESOURCE ]
  then
     echo "ERROR: The gateway resource was not found."
     exit 1
fi

# must create action group (AG) in the App Gateway resource group if it doesn't already exist...
# or select an existing action group and assign the full name to the ACTION_GROUP variable.
ACTION_GROUP="Application Gateway Administrators"
#ACTION_GROUP_RESOURCE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/microsoft.insights/actionGroups/$ACTION_GROUP"
ACTION_GROUP_RESOURCE=$(az monitor action-group list --query "[?name==\`$ACTION_GROUP\`].{Id:id}" -o tsv)

if [ -z $ACTION_GROUP_RESOURCE ] 
  then
    echo "ERROR: The action group resource was not found."
    exit 1
fi

# choose a threshold value (# of occurrences) over a timespan (EVAL_WINDOW) evaluated at EVAL_FREQUENCY
THRESHOLD=10
EVAL_FREQUENCY=1m
EVAL_WINDOW=5m

# create the alert, which will be deployed in the RG named above.

az monitor metrics alert create  \
    --name $ALERT_NAME  \
    --description "Client 4xx errors exceed threshold"  \
    --resource-group $RESOURCE_GROUP  \
    --scopes $GATEWAY_RESOURCE  \
    --condition "total ResponseStatus >= $THRESHOLD where HttpStatusGroup includes $HTTP_STATUS"  \
    --evaluation-frequency $EVAL_FREQUENCY  \
    --window-size $EVAL_WINDOW  \
    --action $ACTION_GROUP_RESOURCE



