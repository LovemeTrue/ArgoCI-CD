#!/usr/bin/env bash

: ${ELMA365_DUMPPATH:=""}
: ${COMMAND:=""}
: ${NAMESPACE:=""}
: ${NODESELECTOR:=""}
: ${CRONJOB:=""}
: ${KUBECTL_CMD:="kubectl"}
: ${CUSTOM_KUBECTL_CMD:=""}
: ${IMAGE_TAG:="0.2.2"}

function usage() {
  echo "Usage: elma365db.sh  --dump (--restore) \\
                     --namespace <namespace> \\
                     --path <path> \\
                     --parts <postgres,mongo,s3> \\

                    optional:
                    [ --kubeconfig <config path> ]
                    [ --context <context> ]
                    [ --nodeselector <\"key1: 'value1'\"> ]
                    [ --cronjob <schedule> ]"
  exit 2
}

dump() {
  cat << EOF | ${KUBECTL_CMD} apply -n $NAMESPACE -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: elma365-db
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: elma365-dbadmin
subjects:
  - kind: ServiceAccount
    name: elma365-db
    namespace: $NAMESPACE
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: batch/v1
kind: $CRONJOB_KIND
metadata:
  name: elma365db
spec:
  $CRONJOB_FAIL_HISTORY
  $CRONJOB_SUCCESS_HISTORY
  $CRONJOB_POLICY
  $CRONJOB_SHEDULE
  $CRONJOB_JOBTEMPLATE
    $JOB_METADATA
      $JOB_ANNOTATIONS
        $JOB_ANNOTATIONS_TEXT
    spec:
      $CRONJOB_TEMPLATE
        $CRONJOB_METADATA
          $CRONJOB_ANNOTATIONS
            $CRONJOB_ANNOTATIONS_TEXT
        $CRONJOB_SPEC
$CRONJOB_SPACE      serviceAccountName: elma365-db
$CRONJOB_SPACE      volumes:
$CRONJOB_SPACE        - name: backup
$CRONJOB_SPACE          hostPath:
$CRONJOB_SPACE            path: $ELMA365_DUMPPATH
$CRONJOB_SPACE      containers:
$CRONJOB_SPACE        - name: dump-restore
$CRONJOB_SPACE          image: hub.elma365.tech/elma365/onpremise/elma365db:${IMAGE_TAG}
$CRONJOB_SPACE          imagePullPolicy: Always
$CRONJOB_SPACE          securityContext:
$CRONJOB_SPACE            privileged: true
$CRONJOB_SPACE          command:
$CRONJOB_SPACE            - "dump-restore"
$CRONJOB_SPACE          args: ["dump", "$NAMESPACE"]
$CRONJOB_SPACE          envFrom:
$CRONJOB_SPACE          - secretRef:
$CRONJOB_SPACE              name: elma365-db-connections
$CRONJOB_SPACE          env:
$CRONJOB_SPACE          - name: ELMA365_VERSION
$CRONJOB_SPACE            valueFrom:
$CRONJOB_SPACE              configMapKeyRef:
$CRONJOB_SPACE                name: elma365-env-config
$CRONJOB_SPACE                key: ELMA365_VERSION
$CRONJOB_SPACE          - name: ELMA365_DUMPPARTS
$CRONJOB_SPACE            value: $ELMA365_DUMPPARTS
$CRONJOB_SPACE          volumeMounts:
$CRONJOB_SPACE            - mountPath: /mnt/backup
$CRONJOB_SPACE              name: backup
$CRONJOB_SPACE      nodeSelector: ${NODESELECTOR_NULL}
$CRONJOB_SPACE        ${NODESELECTOR}
$CRONJOB_SPACE      restartPolicy: Never
$CRONJOB_SPACE  backoffLimit: 0
EOF
}

restore() {
  cat << EOF | ${KUBECTL_CMD} apply -n $NAMESPACE -f - > /dev/null 2>&1
apiVersion: v1
kind: ServiceAccount
metadata:
  name: elma365-db
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: elma365-dbadmin
subjects:
  - kind: ServiceAccount
    name: elma365-db
    namespace: $NAMESPACE
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: batch/v1
kind: Job
metadata:
  name: elma365db
spec:
  template:
    metadata:
      annotations:
        linkerd.io/inject: disabled
    spec:
      serviceAccountName: elma365-db
      volumes:
        - name: backup
          hostPath:
            path: $ELMA365_DUMPPATH
      containers:
        - name: dump-restore
          image: hub.elma365.tech/elma365/onpremise/elma365db:${IMAGE_TAG}
          imagePullPolicy: Always
          securityContext:
            privileged: true
          command:
            - "dump-restore"
          args: ["restore", "$NAMESPACE"]
          env:
          - name: ELMA365_DUMPPARTS
            value: $ELMA365_DUMPPARTS
          volumeMounts:
            - mountPath: /mnt/backup
              name: backup
      nodeSelector: ${NODESELECTOR_NULL}
        ${NODESELECTOR}
      restartPolicy: Never
  backoffLimit: 0
EOF
}

confirm() {
    read -r -p "${1:-This action will stop all services, make dump and start services back. Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            exit 0
            ;;
    esac
}

if [ ! -z "$CUSTOM_KUBECTL_CMD" ]
then
  KUBECTL_CMD="$CUSTOM_KUBECTL_CMD"
fi

PARSED_ARGUMENTS=$(getopt -a -n elma365db.sh -o '' --longoptions dump,dump-kind,restore,restore-kind,namespace:,path:,parts:,kubeconfig:,context:,nodeselector:,cronjob:, -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
  usage
fi

eval set -- "$PARSED_ARGUMENTS"
while :
do
  case "$1" in
    --dump) COMMAND="dump"; shift ;;
    --dump-kind) COMMAND="dump-kind"; shift ;;
    --restore) COMMAND="restore"; shift ;;
    --restore-kind) COMMAND="restore-kind"; shift ;;
    --namespace) NAMESPACE="$2"; shift 2 ;;
    --path) ELMA365_DUMPPATH="$2"; shift 2 ;;
    --parts) ELMA365_DUMPPARTS="$2"; shift 2 ;;
    --kubeconfig) KUBECTL_CMD="${KUBECTL_CMD} --kubeconfig=${2}"; shift 2 ;;
    --context) KUBECTL_CMD="${KUBECTL_CMD} --context=${2}"; shift 2 ;;
    --nodeselector) NODESELECTOR="${2}"; shift 2 ;;
    --cronjob) CRONJOB="${2}"; shift 2 ;;
    --) shift; break ;;
    *) echo "Unexpected option: $1 - this should not happen."
       usage ;;
  esac
done


if [ "$COMMAND" = "" ]; then
  echo "Choose operation with '--dump' or '--restore' option"
  echo
  usage
  exit 1
fi

if [ "$NAMESPACE" = "" ]; then
  echo "Namespace don't set. Use '--namespace' option"
  echo
  usage
  exit 1
fi

if [ "$ELMA365_DUMPPATH" = "" ]; then
  echo "Path for $COMMAND don't set. Use '--path' option"
  echo
  usage
  exit 1
fi

if [ "$ELMA365_DUMPPARTS" = "" ]; then
    ELMA365_DUMPPARTS=""
  else
    for i in $(echo $ELMA365_DUMPPARTS | sed "s/,/ /g"); do
      if [[ $i != @(postgres|mongo|s3) ]]; then
        echo "Parts for $COMMAND is incorrect. Use 'postgres,mongo,s3' for option '--parts'"
        echo
        usage
        exit 1
      fi
    done
fi

if [ "$NODESELECTOR" = "" ]; then
  NODESELECTOR_NULL="{}"
  NODESELECTOR=""
else
  NODESELECTOR_NULL=""
  NODESELECTOR="${NODESELECTOR}"
fi

if [ "$CRONJOB" = "" ]; then
  CRONJOB_KIND="Job"
  CRONJOB_FAIL_HISTORY=""
  CRONJOB_SUCCESS_HISTORY=""
  CRONJOB_POLICY=""
  CRONJOB_SHEDULE=""
  CRONJOB_JOBTEMPLATE="template:"
  CRONJOB_TEMPLATE=""
  CRONJOB_SPEC=""
  CRONJOB_SPACE=""
  CRONJOB_METADATA=""
  CRONJOB_ANNOTATIONS=""
  CRONJOB_ANNOTATIONS_TEXT=""
  JOB_METADATA="metadata:"
  JOB_ANNOTATIONS="annotations:"
  JOB_ANNOTATIONS_TEXT="linkerd.io/inject: disabled"
else
  CRONJOB_KIND="CronJob"
  CRONJOB_FAIL_HISTORY="failedJobsHistoryLimit: 1"
  CRONJOB_SUCCESS_HISTORY="successfulJobsHistoryLimit: 0"
  CRONJOB_POLICY="concurrencyPolicy: Forbid"
  CRONJOB_POLICY="schedule: '${CRONJOB}'"
  CRONJOB_JOBTEMPLATE="jobTemplate:"
  CRONJOB_TEMPLATE="template:"
  CRONJOB_SPEC="spec:"
  CRONJOB_SPACE="    "
  CRONJOB_METADATA="metadata:"
  CRONJOB_ANNOTATIONS="annotations:"
  CRONJOB_ANNOTATIONS_TEXT="linkerd.io/inject: disabled"
  JOB_METADATA=""
  JOB_ANNOTATIONS=""
  JOB_ANNOTATIONS_TEXT=""
fi

${KUBECTL_CMD} delete job elma365db -n $NAMESPACE > /dev/null 2>&1
${KUBECTL_CMD} delete job -l tier=elma365 -n $NAMESPACE > /dev/null 2>&1

if [ "$COMMAND" = "dump" ]; then
  confirm && dump
fi

if [ "$COMMAND" = "dump-kind" ]; then
  COMMAND="Dump"
  dump
fi

if [ "$COMMAND" = "restore" ]; then
  ELMA365_TMP_FILE="$(mktemp -q values-elma365-XXXXXX.yaml)"
  if [ -f "values-elma365.yaml" ]; then
    cat values-elma365.yaml | sed "/^elma365:$/d" > ${ELMA365_TMP_FILE}
    ${KUBECTL_CMD} -n $NAMESPACE delete configmap elma365-values > /dev/null 2>&1
    ${KUBECTL_CMD} -n $NAMESPACE create configmap elma365-values --from-file=values-elma365.yaml=${ELMA365_TMP_FILE}
    rm -f "${ELMA365_TMP_FILE}"
    restore
  elif [ -f "values.yaml" ]; then
    cat values.yaml | sed "/^elma365:$/d" > ${ELMA365_TMP_FILE}
    ${KUBECTL_CMD} -n $NAMESPACE delete configmap elma365-values > /dev/null 2>&1
    ${KUBECTL_CMD} -n $NAMESPACE create configmap elma365-values --from-file=values-elma365.yaml=${ELMA365_TMP_FILE}
    rm -f "${ELMA365_TMP_FILE}"
    restore
  else
    echo "Failed: file values-elma365.yaml or values.yaml not found"
    exit 1
  fi
fi

if [ "$COMMAND" = "restore-kind" ]; then
  COMMAND="Restore"
  restore
fi

if [ "$CRONJOB" = "" ]; then
  echo "Waiting for ${COMMAND}"
  sleep 30
  while true; do
    status=$(${KUBECTL_CMD} -n $NAMESPACE logs -l job-name=elma365db --tail=-1  | grep -i "${COMMAND} successful" 2>/dev/null) || true
    if [[ "$status" =~ "${COMMAND} successful" ]]; then
      LOGS=$(${KUBECTL_CMD} -n $NAMESPACE logs -l job-name=elma365db --tail=-1  | grep -i "Dump successful" | awk '{print substr($0, index($0,$5))}')
      echo "${COMMAND} successful ${LOGS}"
      break
    fi
    status=$(${KUBECTL_CMD} -n $NAMESPACE get jobs elma365db -o jsonpath='{.status.conditions[0].type}' 2>/dev/null) || true
    if [[ "$status" =~ "Complete" ]]; then
      LOGS=$(${KUBECTL_CMD} -n $NAMESPACE logs -l job-name=elma365db --tail=-1  | grep -i "Dump successful" | awk '{print substr($0, index($0,$5))}')
      echo "${COMMAND} successful ${LOGS}"
      break
    fi
    if [[ "$status" =~ "Faile" ]]; then
      echo "${COMMAND} failed"
      break
    fi
    sleep 15
  done
fi
