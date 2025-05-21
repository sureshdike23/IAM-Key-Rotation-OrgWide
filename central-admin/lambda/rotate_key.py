import boto3
import json
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns_topic_arn = os.environ['SNS_TOPIC_ARN']
rotation_role_name = os.environ['ROTATION_ROLE_NAME']
accounts_users_json = os.environ['ACCOUNTS_USERS_JSON']

def send_sns_alert(subject, message):
    sns = boto3.client('sns')
    sns.publish(
        TopicArn=sns_topic_arn,
        Subject=subject,
        Message=message
    )

def assume_role(account_id):
    sts = boto3.client('sts')
    try:
        role_arn = f"arn:aws:iam::{account_id}:role/{rotation_role_name}"
        response = sts.assume_role(
            RoleArn=role_arn,
            RoleSessionName='KeyRotationSession'
        )
        credentials = response['Credentials']
        return boto3.Session(
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken']
        )
    except Exception as e:
        send_sns_alert(
            f"[ERROR] Failed to assume role in account {account_id}",
            str(e)
        )
        return None

def rotate_keys_for_user(session, username):
    iam = session.client('iam')
    try:
        keys = iam.list_access_keys(UserName=username)['AccessKeyMetadata']
        if len(keys) >= 2:
            # Delete the oldest if already 2 exist
            oldest_key = sorted(keys, key=lambda k: k['CreateDate'])[0]
            iam.delete_access_key(UserName=username, AccessKeyId=oldest_key['AccessKeyId'])

        new_key = iam.create_access_key(UserName=username)['AccessKey']

        logger.info(f"New key created for {username}")
        send_sns_alert(f"[INFO] New key created for {username}", json.dumps(new_key))

        # Schedule deletion of the old key in 8 days
        if keys:
            old_key_id = keys[-1]['AccessKeyId']
            iam.update_access_key(UserName=username, AccessKeyId=old_key_id, Status='Inactive')
            logger.info(f"Marked {old_key_id} as Inactive")
            send_sns_alert(f"[INFO] Key {old_key_id} marked Inactive", f"For user: {username}")

    except Exception as e:
        logger.error(f"Key rotation failed for {username}: {str(e)}")
        send_sns_alert(f"[ERROR] Key rotation failed for {username}", str(e))

def lambda_handler(event, context):
    logger.info("Starting org-wide IAM key rotation")
    accounts_users = json.loads(accounts_users_json)

    for account_id, users in accounts_users.items():
        session = assume_role(account_id)
        if not session:
            continue
        for username in users:
            rotate_keys_for_user(session, username)

    logger.info("Rotation complete")
    return {"status": "rotation complete"}
