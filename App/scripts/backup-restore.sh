#!/bin/bash

# MongoDB yedekleme
backup_mongodb() {
    POD_NAME=$(kubectl get pod -l app=mongodb -o jsonpath="{.items[0].metadata.name}")
    kubectl exec $POD_NAME -- mongodump --out /backup
    kubectl cp $POD_NAME:/backup ./mongodb-backup
}

# Yedekten geri yükleme
restore_mongodb() {
    POD_NAME=$(kubectl get pod -l app=mongodb -o jsonpath="{.items[0].metadata.name}")
    kubectl cp ./mongodb-backup $POD_NAME:/backup
    kubectl exec $POD_NAME -- mongorestore /backup
}