import boto3
import os

ec2 = boto3.client("ec2")


def lambda_handler(event, context):
    action = event.get("action", "")
    tag_key = os.environ.get("TAG_KEY", "Schedule")
    tag_value = os.environ.get("TAG_VALUE", "mon-fri_8-16")

    response = ec2.describe_instances(
        Filters=[
            {"Name": f"tag:{tag_key}", "Values": [tag_value]},
            {"Name": "instance-state-name", "Values": ["running", "stopped"]},
        ]
    )

    instance_ids = []
    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            instance_ids.append(instance["InstanceId"])

    if not instance_ids:
        print(f"No instances found with tag {tag_key}={tag_value}")
        return {"status": "no_instances_found"}

    if action == "start":
        ec2.start_instances(InstanceIds=instance_ids)
        print(f"Started instances: {instance_ids}")
        return {"status": "started", "instances": instance_ids}
    elif action == "stop":
        ec2.stop_instances(InstanceIds=instance_ids)
        print(f"Stopped instances: {instance_ids}")
        return {"status": "stopped", "instances": instance_ids}
    else:
        print(f"Unknown action: {action}")
        return {"status": "unknown_action", "action": action}
