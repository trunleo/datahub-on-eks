import boto3
import json
import logging
import os
import dateutil.parser
from datetime import datetime

client = boto3.client('ec2')

def lambda_handler(event, context):
    setup_logging()
    log.info('In Main Handler')
    log.info(json.dumps(event))
    numConnections=0
    # lastDownTS=None
    # vpnId= event['vpnId']

    vpnId='vpn-0e904bda83ed001db'
    # Retrieves TGW ID from the event's VPN ID
    response = client.describe_vpn_connections(VpnConnectionIds=[vpnId])
    primaryTGWId = response['VpnConnections'][0]['TransitGatewayId']
    print("TransitGateway is " + primaryTGWId)
    log.info('Transit Gateway Id  ' + primaryTGWId)
    
    # Find Attachment ID of the primary VPN
    primaryAttachmentId = client.describe_transit_gateway_attachments(
        Filters=[{'Name': 'transit-gateway-id', 'Values': [primaryTGWId]}, {'Name': 'resource-id', 'Values': [vpnId]}])[
        'TransitGatewayAttachments'][0]['TransitGatewayAttachmentId']
    log.info('Primary VPN ' + vpnId + ' has Transit Gateway attachment Id  ' + primaryAttachmentId)
    print('Primary VPN ' + vpnId + ' has Transit Gateway attachment Id  ' + primaryAttachmentId)
    
    # Find Primary Key that will be used to find the backup VPN. Get PrimaryVPNKey
    tags = response['VpnConnections'][0]['Tags']
    primaryVPNKey = next((item for item in tags if item["Value"] == "PRIMARY"),
                         False)
    log.info('Primary VPN ' + vpnId + ' has been tagged with  ' + str(primaryVPNKey))
    print('Primary VPN ' + vpnId + ' has been tagged with  ' + str(primaryVPNKey))

    # Check if we have valid tags
    if primaryVPNKey is not False:
        try:
            primaryVPNKey = ((primaryVPNKey)['Key'])
            # Find backup VPN
            backupVPN = client.describe_vpn_connections(
                Filters=[{'Name': 'tag:' + primaryVPNKey, 'Values': ['BACKUP']}])
            backupVPNId = backupVPN['VpnConnections'][0]['VpnConnectionId']
            log.info('Backup VPN for ' + vpnId + " is " + backupVPNId)
            backupVPNStatus = backupVPN['VpnConnections']
            for tunnel in backupVPNStatus:
                if tunnel['State'] == 'available':
                    numConnections += 1
                    activeTunnels = 0
                    if tunnel['VgwTelemetry'][0]['Status'] == 'UP':
                        activeTunnels += 1
                    if tunnel['VgwTelemetry'][1]['Status'] == 'UP':
                        activeTunnels += 1
            log.info(str(activeTunnels) + " tunnel(s) are active on " + backupVPNId)
            if activeTunnels > 0: # If activeTunnels is greater than 0. Proceed with the change, else stop
                # Find Attachment ID of the Backup VPN
                backupAttachmentId = client.describe_transit_gateway_attachments(
                    Filters=[{'Name': 'transit-gateway-id', 'Values': [primaryTGWId]},
                             {'Name': 'resource-id', 'Values': [backupVPNId]}])['TransitGatewayAttachments'][0]['TransitGatewayAttachmentId']
                log.info('Backup VPN ' + backupVPNId + ' has Transit Gateway attachment Id  ' + backupAttachmentId)
                print("Attachment of VPN Backup is " + backupAttachmentId)
                # Describe and find all TGW route tables associated with TGW
                alltgwRTs = client.describe_transit_gateway_route_tables(
                    Filters=[{'Name': 'transit-gateway-id', 'Values': [primaryTGWId]},
                             {'Name': 'state', 'Values': ['available']}])['TransitGatewayRouteTables']
                tgwRts = []
                for rts in alltgwRTs:
                    tgwRts.append(rts['TransitGatewayRouteTableId'])
                # Loop Through TGW route tables and find destination cidr block
                # Transit Gateway Route Table ID 
                tgwRouteTable = tgwRts[0]
                print("Transit Gateway Route Table Id is ", tgwRouteTable)
                
                # Get prefix list ID 
                for routeTable in tgwRts:
                    destCidrBlock = []
                    allCidrBlock = client.search_transit_gateway_routes(TransitGatewayRouteTableId=routeTable, Filters=[
                        {'Name': 'attachment.transit-gateway-attachment-id', 'Values': [primaryAttachmentId]},
                        {'Name': 'type', 'Values': ['propagated']}])['Routes']
                prefix = allCidrBlock[0]['PrefixListId']
                print("Prefix list id is ", prefix)
                # Change the prefix list reference from Attachment Primary to Attachment Backup
                # client.modify_transit_gateway_prefix_list_reference(TransitGatewayRouteTableId=tgwRouteTable, \
                # PrefixListId=prefix, TransitGatewayAttachmentId=backupAttachmentId)
                    # for cidrs in allCidrBlock:
                    #     # rtCidr[routeTable]=destCidrBlock.append(cidrs['DestinationCidrBlock'])
                    #     destCidrBlock.append(cidrs['DestinationCidrBlock'])
                    #     rtCidr[routeTable] = destCidrBlock
                # # Do replace for both TGW route tables.
                # for rt in rtCidr:
                #     for prefix in rtCidr[rt]:
                #         log.info('Replacing TGW RT ' + rt + ' Route ' + prefix + ' with ' + backupAttachmentId)
                        # client.replace_transit_gateway_route(DestinationCidrBlock=prefix, TransitGatewayRouteTableId=rt,
                        # TransitGatewayAttachmentId=backupAttachmentId)
                
            else:
                log.info('No Active Tunnel Found on backup VPN ' + backupVPNId + ' not taking any actions ')
                print('No Active Tunnel Found on backup VPN ' + backupVPNId + ' not taking any actions ')
        except Exception as e:
            log.error(e)
    elif primaryVPNKey is False:
        log.info('No valid Tags found. Function will not taking any actions ')
        print('No valid Tags found. Function will not taking any actions ')

def setup_logging():
    """Setup Logging."""
    global log
    log = logging.getLogger()
    log_levels = {'INFO': 20, 'WARNING': 30, 'ERROR': 40}

    if 'logging_level' in os.environ:
        log_level = os.environ['logging_level'].upper()
        if log_level in log_levels:
            log.setLevel(log_levels[log_level])
        else:
            log.setLevel(log_levels['ERROR'])
            log.error("The logging_level environmenthas been tagged with variable is not set \
                      to INFO, WARNING, or ERROR. \
                      The log level is set to ERROR")
    else:
        log.setLevel(log_levels['ERROR'])
        log.warning('The logging_level environment variable is not set.')
        log.warning('Setting the log level to ERROR')
    log.info('Logging setup complete - set to log level ' + str(log.getEffectiveLevel()))