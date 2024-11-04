{
    "Comment": "State machine for finance-fmi-spa-db-prod scheduler",
    "StartAt": "Daily Backup Choice",
    "States": {
      "Daily Backup Choice": {
        "Type": "Choice",
        "InputPath": "$",
        "OutputPath": "$",
        "Choices": [
          {
            "Variable": "$.action",
            "StringEquals": "stop",
            "Next": "Daily Backup State"
          },
          {
            "Variable": "$.action",
            "StringEquals": "start",
            "Next": "Scheduler State"
          } 
        ]
      },
      "Daily Backup State": {
        "Comment": "A Scheduler State is used for database class change process",
        "Type": "Task",
        "Resource": "arn:aws:lambda:ap-southeast-1:682270135282:function:RenovaRdsBackup",
        "ResultPath": "$.scheduler",
        "OutputPath": "$",
        "Catch": [ {
          "ErrorEquals": ["States.TaskFailed"],
          "Next": "Fallback Notification"
        } ],
        "Next": "Wait 30 minutes"
      },
      "Wait 30 minutes": {
        "Comment": "A Wait state delays 30 minutes for Check State.",
        "Type": "Wait",
        "Seconds": 1800,
        "Next": "Scheduler State"
      },
      "Scheduler State": {
        "Comment": "A Scheduler State is used for database class change process",
        "Type": "Task",
        "Resource": "arn:aws:lambda:ap-southeast-1:682270135282:function:RenovaRdsScheduler",
        "ResultPath": "$.scheduler",
        "OutputPath": "$",
        "Catch": [ {
          "ErrorEquals": ["States.TaskFailed"],
          "Next": "Fallback Notification"
        } ],
        "Next": "Monthly Backup Choice"
      },
      "Monthly Backup Choice": {
        "Type": "Choice",
        "OutputPath": "$",
        "Choices": [ {
            "Variable": "$.scheduler.monthly_backup",
            "StringEquals": "YES",
            "Next": "Wait 30 minutes for monthly backup"
        }, {
            "Variable": "$.scheduler.monthly_backup",
            "StringEquals": "NO",
            "Next": "Check Notification"
        } ]
      },
      "Wait 30 minutes for monthly backup": {
        "Comment": "A Wait state delays 30 minutes for Check State.",
        "Type": "Wait",
        "Seconds": 1800,
        "Next": "Monthly Backup State"
      },
      "Monthly Backup State": {
        "Comment": "A Monthly Backup State is used for database class change process",
        "Type": "Task",
        "Resource": "arn:aws:lambda:ap-southeast-1:682270135282:function:RenovaRdsBackup",
        "ResultPath": "$.monthlybackup",
        "OutputPath": "$",
        "Catch": [ {
          "ErrorEquals": ["States.TaskFailed"],
          "Next": "Fallback Notification"
        } ],
        "Next": "Check Notification"
      },
      "Fallback Notification": {
        "Comment": "A SNS Scheduler Fallback Notification state",
        "Type": "Task",
        "Resource": "arn:aws:states:::sns:publish",
        "Parameters": {
          "Subject": "Database Scheduler Status: Fallback",
          "Message": "The state machine execution was failed to execute!",
          "TopicArn": "arn:aws:sns:ap-southeast-1:682270135282:RenovaRdsScheduler"
        },
        "End": true
      },
      "Check Notification": {
        "Type": "Choice",
        "Choices": [
          {
            "Variable": "$.scheduler.status",
            "BooleanEquals": true,
            "Next": "Check Success Notification"
          }
        ],
        "Default": "Check Failure Notification"
      },
      "Check Success Notification": {
        "Comment": "A SNS Check Success Notification State",
        "Type": "Task",
        "Resource": "arn:aws:states:::sns:publish",
        "Parameters": {
          "Subject": "Database Scheduler Status: Success",
          "Message": "The scheduler activity is executed sucessfully!",
          "TopicArn": "arn:aws:sns:ap-southeast-1:682270135282:RenovaRdsScheduler"
        },
        "End": true
      },
      "Check Failure Notification": {
        "Comment": "A SNS Check Success Notification State",
        "Type": "Task",
        "Resource": "arn:aws:states:::sns:publish",
        "Parameters": {
          "Subject": "Database Scheduler Status: Failure",
          "Message": "The scheduler activity is failed to execute!",
          "TopicArn": "arn:aws:sns:ap-southeast-1:682270135282:RenovaRdsScheduler"
        },
        "End": true
      }
    }
  }