#  Get the default subscription or look up one by name...
SUBSCRIPTION=$(az account list --query [?isDefault].{Id:id} -o tsv)
#SUBSCRIPTION=$(az account list --query [?SubscriptionName==<Your subscription name here>].{Id:id} -o tsv)

# must set the following values to match a current deployment
RESOURCE_GROUP="cpgateway"
GATEWAY_NAME="cpgateway"

# set a unique name for this query
ALERT_NAME="Client_4xx_errors"   #this value must be unique for every invocation of this script

HTTP_STATUS="4xx"   #must correspond to a class of HTTP returns, i.e. 3xx, 4xx, 5xx

# must create action group (AG) in the App Gateway resource group if it doesn't already exist...
# or select an existing action group and assign the full name to the ACTION_GROUP variable.
ACTION_GROUP="Application Gateway Administrators"
#ACTION_GROUP_RESOURCE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/microsoft.insights/actionGroups/$ACTION_GROUP"
ACTION_GROUP_RESOURCE=$(az monitor action-group list --query "[?name==\`$ACTION_GROUP\`].{Id:id}" -o tsv)

# choose a threshold value (# of occurrences) over a timespan (EVAL_WINDOW) evaluated at EVAL_FREQUENCY
THRESHOLD=10
EVAL_FREQUENCY=1m
EVAL_WINDOW=5m

# create the alert, which will be deployed in the RG named above.

az monitor metrics alert create  \
    --name $ALERT_NAME  \
    --description "Client 4xx errors exceed threshold"  \
    --resource-group $RESOURCE_GROUP  \
    --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/applicationGateways/$GATEWAY_NAME"  \
    --condition "total ResponseStatus >= $THRESHOLD where HttpStatusGroup includes $HTTP_STATUS"  \
    --evaluation-frequency $EVAL_FREQUENCY  \
    --window-size $EVAL_WINDOW  \
    --action $ACTION_GROUP_RESOURCE


