import os
import re
import sys
from datetime import datetime, timedelta
import boto3
import logging


account_id = os.environ.get('ACCOUNT_ID')
service = os.environ.get('SERVICE', 'unknown')
app_tier = os.environ.get('APP_TIER', 'unknown')
log_level = os.environ.get('LOG_LEVEL', 'INFO')
aws_region = os.environ.get('AWS_REGION')
function_name = os.environ.get('FUNCTION_NAME')

def setup_logger(level='INFO', extras={}):
    extras['service'] = service

    logger = logging.getLogger()
    for h in logger.handlers:
        logger.removeHandler(h)

    format_str = '%(asctime)s %(name)s %(levelname)s %(message)s'
    formatter = logging.Formatter(format_str)

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(formatter)

    logger.addHandler(handler)
    logger.setLevel(log_level.upper())
    logger = logging.LoggerAdapter(logger, extras)
    return logger

logger = setup_logger(level=log_level)
ec2 = boto3.resource('ec2',region_name=aws_region)
ec2img = boto3.client('ec2',region_name=aws_region)


def handler(event, context):
    sns = boto3.client(service_name="sns", region_name='{}'.format(aws_region))

    # Gather AMIs and figure out which ones to delete
    my_images = ec2.images.filter(Owners=[account_id])
        

    # Don't delete images in use
    used_images = {
        instance.image_id for instance in ec2.instances.all()
    }

        
    # Keep everything younger than two weeks
    young_images = set()
    for image in my_images:
        created_at = datetime.strptime(
            image.creation_date,
            "%Y-%m-%dT%H:%M:%S.000Z",
        )
        if created_at > datetime.now() - timedelta(14):
            young_images.add(image.id)
        

    # Keep latest one
    latest = dict()
    for image in my_images:
        split = image.name.split('-')
        try:
            timestamp = int(split[-1])
        except ValueError:
            continue
        name = '-'.join(split[:-1])
        if(
                name not in latest
                or timestamp > latest[name][0]
        ):
            latest[name] = (timestamp, image)
    latest_images = {image.id for (_, image) in latest.values()}


    #looks for images marked with a tag-key named 'safe'
    marked_safe = set()
    my_amis = ec2img.describe_images(Filters=[{'Name':'tag-key', 'Values':['safe']}])
    for i in my_amis.get("Images"):
                marked_safe.add(i.get("ImageId"))




    # Delete everything
    safe = used_images | young_images | latest_images | marked_safe
    marked_name = []
    resource_id = []
    for image in (
        image for image in my_images if image.id not in safe
    ):
        logger.info('Marked for deregistration: {} ({})'.format(image.name, image.id))
        marked_name.append(image.name)
        resource_id.append(image.id)
       
    if not marked_name:
        sns.publish(
                TopicArn = 'arn:aws:sns:{}:{}:{}_ec2_amicleanup_notify'.format(aws_region, account_id, aws_region),
                Subject  = "{}".format(function_name),
                Message  = "None at this time."
                )
    else:
        marked_name = '\n'.join(marked_name)
        sns.publish(
           TopicArn = 'arn:aws:sns:{}:{}:{}_ec2_amicleanup_notify'.format(aws_region, account_id, aws_region),
           Subject  = "{}".format(function_name),
           Message  = "Marked for Deletion: \n{}".format(marked_name)
            )
        
        #tags instances that were marked with a Deprecated tag with a Value of %currentdate + 2 weeks 
        for imageami in resource_id:
                ec2.create_tags(Resources=[imageami], Tags=[{'Key': 'deprecated', 'Value': 'true'},{'Key': 'deprecated_date', 'Value': '{}Z'.format(datetime.now().replace(microsecond=0) + timedelta(14))}])
        
    
    ##snapshot area will need potential rework; the call itself generates
    ##an enormous amount of return and needs minimum 25s / 400mb to run and parse
    # Delete unattached snapshots
    #print('Deleting snapshots.')
    #images = [image.id for image in ec2.images.all()]
    #for snapshot in ec2.snapshots.filter(OwnerIds=[account_id]):
    #    print('Checking {}'.format(snapshot.id))
    #    r = re.match(r".*for (ami-.*) from.*", snapshot.description)
    #    if r:
    #        if r.groups()[0] not in images:
    #            print('Deleting {}'.format(snapshot.id))
                #snapshot.delete()
