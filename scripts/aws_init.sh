#! /bin/bash

aws rds create-db-parameter-group \
    --db-parameter-group-name confluent-mysql8 \
    --db-parameter-group-family MySQL8.0 \
    --description "Parameter group binlog setting for cdc"

aws rds modify-db-parameter-group \
    --db-parameter-group-name confluent-mysql8 \
    --parameters "ParameterName=binlog_format,ParameterValue=ROW,ApplyMethod=immediate"

aws rds modify-db-instance --db-instance-identifier eap-test-with-nlb-shiv --db-parameter-group-name confluent-mysql8 --apply-immediately

aws rds reboot-db-instance --db-instance-identifier eap-test-with-nlb-shiv