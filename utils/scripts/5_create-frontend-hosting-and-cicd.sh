#!/bin/bash

cd "$WORKING_DIR"/src/hiperium-city-tasks-pwa/ || {
  echo "Error moving to the Tasks Service 'frontend' directory."
  exit 1
}

echo ""
echo "Getting information from AWS. Please wait..."

echo ""
alb_endpoint=$(aws cloudformation describe-stacks       \
  --stack-name hiperium-city-tasks-"$TASK_SERVICE_ENV"  \
  --query "Stacks[0].Outputs[?contains(OutputKey,'PublicLoadBalancerDNSName')].OutputValue"  \
  --output text)
if [ -z "$alb_endpoint" ]; then
  echo "ALB endpoint NOT found on CloudFormation."
  exit 0
fi
echo "ALB Endpoint: $alb_endpoint"

authStack=$(aws cloudformation list-stacks --output text \
  --query "StackSummaries[?contains(StackName, 'authHiperiumCityIdP') && (StackStatus=='CREATE_COMPLETE' || StackStatus=='UPDATE_COMPLETE')].[StackName]" \
  --profile "$IDP_AWS_PROFILE")
if [ -z "$authStack" ]; then
  echo "No Tasks Service Identity Provider (IdP) stack found on CloudFormation."
  exit 0
fi
echo "IdP Service Stack found: $authStack"

user_pool_id=$(aws cloudformation describe-stacks   \
  --stack-name "$authStack"                         \
  --query "Stacks[0].Outputs[0].OutputValue"        \
  --output text                                     \
  --profile "$IDP_AWS_PROFILE")
if [ -z "$user_pool_id" ]; then
  echo "No Cognito User Pool found on CloudFormation."
  exit 0
fi
echo "User Pool ID found: $user_pool_id"

cognito_app_client_id_web=$(aws cloudformation describe-stacks  \
  --stack-name "$authStack"                             \
  --query "Stacks[0].Outputs[1].OutputValue"            \
  --output text                                         \
  --profile "$IDP_AWS_PROFILE")
if [ -z "$cognito_app_client_id_web" ]; then
  echo "No Cognito Client ID Web found on CloudFormation."
  exit 0
fi
echo "Cognito Client ID Web: $cognito_app_client_id_web"

amplify_app_id=$(aws amplify list-apps --query "apps[?name=='HiperiumCityTasksPWA'].appId" --output text)
if [ -z "$amplify_app_id" ]; then
  echo "No Amplify project ID found on CloudFormation."
  exit 0
fi

echo ""
echo "UPDATING IONIC ENVIRONMENT CONFIG FILES..."
sed -e "s/ALB_ENDPOINT/$alb_endpoint/g; s/AWS_REGION/$AWS_REGION/g; s/COGNITO_USER_POOL_ID/$user_pool_id/g; s/COGNITO_APP_CLIENT_ID_WEB/$cognito_app_client_id_web/g; s/TASK_SERVICE_ENV/$TASK_SERVICE_ENV/g; s/AMPLIFY_APP_ID/$amplify_app_id/g;" \
  "$WORKING_DIR"/utils/scripts/templates/ionic/ionic-environment-"$TASK_SERVICE_ENV" > src/environments/environment."$TASK_SERVICE_ENV".ts
echo "DONE!"

echo ""
echo "PUSHING CHANGES TO GIT REPOSITORY..."
git add .
git commit -m "Adding Amplify Hosting and CI/CD configuration."
git push --set-upstream origin "$TASK_SERVICE_ENV"
echo "DONE!"

echo ""
echo "CREATING AMPLIFY HOSTING ON AWS..."
echo "The following procedure is manual, so after the Connection to the Git Repository is completed, return to this script to continue."
echo ""
echo "In the next questions, select 'Hosting with Amplify Console' first, and then 'Continuous deployment' to configure the CI/CD Pipeline."
echo "Press any key to continue..."
read -n 1 -s -r -p ""

echo ""
amplify add hosting
echo "DONE!"

echo ""
echo "IMPORTANT!!: Please, add the previous Amplify Domain URL to the 'Allowed OAuth Redirect URLs' on the Hiperium IdP Service."


