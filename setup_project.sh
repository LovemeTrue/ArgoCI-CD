#!/bin/bash

set -e

PROJECT_DIR="deckhouse-ansible"
mkdir -p $PROJECT_DIR/{inventory,group_vars,host_vars,playbooks,roles/{common,tasks},templates,files}

echo "📁 Создание структуры проекта в $PROJECT_DIR..."

# ---------- inventory ----------
cat > $PROJECT_DIR/inventory/hosts.yml <<EOF
all:
  children:
    cluster:
      hosts:
        master:
          ansible_host: 192.168.29.24
        system:
          ansible_host: 91.217.196.183
        worker1:
          ansible_host: 192.168.39.58
        worker2:
          ansible_host: 91.217.196.152
EOF

# ---------- vault.yml ----------
cat > $PROJECT_DIR/vault.yml <<EOF
vault_ssh_user: angelos
vault_ssh_password: lazypeon
admin_password_bcrypt: 'JDJhJDEwJHBrLnBlR0MvYjI0NkxNL2t4RE1YME9TMDc0RTUxWlhma1NtS3E5dG9lY0VBWnZZZEpyeFNx'
EOF

echo "🔐 Шифруем vault.yml..."
cd $PROJECT_DIR
ansible-vault encrypt vault.yml
cd ..

# ---------- group_vars/all.yml ----------
cat > $PROJECT_DIR/group_vars/all.yml <<EOF
ansible_user: angelos
ansible_ssh_private_key_file: ~/.ssh/id_rsa
ansible_become: true
EOF

# ---------- templates/config.yml.j2 ----------
cat > $PROJECT_DIR/templates/config.yml.j2 <<'EOF'
# Общие параметры кластера.
# https://deckhouse.ru/products/kubernetes-platform/documentation/v1/installing/configuration.html#clusterconfiguration
apiVersion: deckhouse.io/v1
kind: ClusterConfiguration
clusterType: Static
# Адресное пространство подов кластера.
podSubnetCIDR: 10.111.0.0/16
# Адресное пространство сети сервисов кластера.
serviceSubnetCIDR: 10.222.0.0/16
kubernetesVersion: "Automatic"
# Домен кластера.
clusterDomain: "cluster.local"
---
# Настройки первичной инициализации кластера Deckhouse.
# https://deckhouse.ru/products/kubernetes-platform/documentation/v1/installing/configuration.html#initconfiguration
apiVersion: deckhouse.io/v1
kind: InitConfiguration
deckhouse:
  imagesRepo: registry.deckhouse.ru/deckhouse/ce
  registryDockerCfg: eyJhdXRocyI6IHsgInJlZ2lzdHJ5LmRlY2tob3VzZS5ydSI6IHt9fX0K
---
# Настройки модуля deckhouse.
# https://deckhouse.ru/products/kubernetes-platform/documentation/v1/modules/deckhouse/configuration.html
apiVersion: deckhouse.io/v1alpha1
kind: ModuleConfig
metadata:
  name: deckhouse
spec:
  version: 1
  enabled: true
  settings:
    bundle: Default
    # Канал обновлений Deckhouse. Канал Early Access достаточно стабилен, его можно использовать в продуктивных окружениях.
    # Если планируется использовать несколько кластеров, то рекомендуется установить на них разные каналы обновлений.
    # Подробнее: https://deckhouse.ru/products/kubernetes-platform/documentation/v1/deckhouse-release-channels.html
    releaseChannel: Stable
    logLevel: Info
---
# Глобальные настройки Deckhouse.
# https://deckhouse.ru/products/kubernetes-platform/documentation/v1/deckhouse-configure-global.html#%D0%BF%D0%B0%D1%80%D0%B0%D0%BC%D0%B5%D1%82%D1%80%D1%8B
apiVersion: deckhouse.io/v1alpha1
kind: ModuleConfig
metadata:
  name: global
spec:
  version: 2
  settings:
    modules:
      # Шаблон, который будет использоваться для составления адресов системных приложений в кластере.
      # Например, Grafana для d8-elma365%s.domain.my будет доступна на домене 'd8-elma365grafana.domain.my'.
      # Домен НЕ ДОЛЖЕН совпадать с указанным в параметре clusterDomain ресурса ClusterConfiguration.
      # Можете изменить на свой сразу, либо следовать шагам руководства и сменить его после установки.
      defaultClusterStorageClass: localpath
      publicDomainTemplate: "d8-elma365%s.domain.my"
---
# Настройки модуля user-authn.
# https://deckhouse.ru/products/kubernetes-platform/documentation/v1/modules/user-authn/configuration.html
apiVersion: deckhouse.io/v1alpha1
kind: ModuleConfig
metadata:
  name: user-authn
spec:
  version: 2
  enabled: true
  settings:
    controlPlaneConfigurator:
      dexCAMode: DoNotNeed
    # Включение доступа к API-серверу Kubernetes через Ingress.
    # https://deckhouse.ru/products/kubernetes-platform/documentation/v1/modules/user-authn/configuration.html#parameters-publishapi
    publishAPI:
      enabled: true
      https:
        mode: Global
        global:
          kubeconfigGeneratorMasterCA: ""
---
# Настройки модуля cni-cilium.
# https://deckhouse.ru/products/kubernetes-platform/documentation/v1/modules/cni-cilium/configuration.html
apiVersion: deckhouse.io/v1alpha1
kind: ModuleConfig
metadata:
  name: cni-cilium
spec:
  version: 1
  # Включить модуль cni-cilium
  enabled: true
  settings:
    # Настройки модуля cni-cilium
    # https://deckhouse.ru/products/kubernetes-platform/documentation/v1/modules/cni-cilium/configuration.html
    tunnelMode: VXLAN
---
# Параметры статического кластера.
# https://deckhouse.ru/products/kubernetes-platform/documentation/v1/installing/configuration.html#staticclusterconfiguration
apiVersion: deckhouse.io/v1
kind: StaticClusterConfiguration
# Список внутренних сетей узлов кластера (например, '10.0.4.0/24'), который
# используется для связи компонентов Kubernetes (kube-apiserver, kubelet...) между собой.
# Укажите, если используете модуль virtualization или узлы кластера имеют более одного сетевого интерфейса.
# Если на узлах кластера используется только один интерфейс, ресурс StaticClusterConfiguration можно не создавать.
  internalNetworkCIDRs:
    - {{ ansible_default_ipv4.network }}/{{ ansible_default_ipv4.netmask | ipaddr('prefix') }}
EOF

# ---------- templates/nodegroup-system.yaml.j2 ----------
cat > $PROJECT_DIR/templates/nodegroup-system.yaml.j2 <<EOF
apiVersion: deckhouse.io/v1
kind: NodeGroup
metadata:
  name: system
spec:
  nodeTemplate:
    labels:
      node-role.deckhouse.io/system: ""
    taints:
      - effect: NoExecute
        key: dedicated.deckhouse.io
        value: system
  nodeType: Static
EOF

# ---------- templates/nodegroup-worker.yaml.j2 ----------
cat > $PROJECT_DIR/templates/nodegroup-worker.yaml.j2 <<EOF
apiVersion: deckhouse.io/v1
kind: NodeGroup
metadata:
  name: worker
spec:
  nodeType: Static
  kubelet:
    maxPods: 200
EOF

# ---------- playbooks/bootstrap.yml ----------
cat > $PROJECT_DIR/playbooks/bootstrap.yml <<'EOF'
- name: Install Deckhouse on master node
  hosts: master
  become: true
  vars_files:
    - ../vault.yml

  tasks:
    - name: Install required packages
      apt:
        name: [docker.io, jq, curl]
        state: present
        update_cache: yes

    - name: Install kubectl
      shell: |
        curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
      args:
        creates: /usr/local/bin/kubectl

    - name: Create config.yml
      template:
        src: ../templates/config.yml.j2
        dest: /root/config.yml

    - name: Install Deckhouse
      shell: |
        docker run --pull=always -it \
        -v "/root/config.yml:/config.yml" \
        -v "/root/.ssh/:/tmp/.ssh/" \
        registry.deckhouse.ru/deckhouse/ce/install:stable bash -c \
        "dhctl bootstrap --ssh-user={{ vault_ssh_user }} \
          --ssh-host={{ ansible_host }} \
          --ssh-agent-private-keys=/tmp/.ssh/id_rsa \
          --config=/config.yml --ask-become-pass"
      args:
        executable: /bin/bash
EOF

# ---------- playbooks/add_nodegroup.yml ----------
cat > $PROJECT_DIR/playbooks/add_nodegroup.yml <<'EOF'
- name: Add system or worker nodes via NodeGroups
  hosts: master
  gather_facts: no
  vars_files:
    - ../vault.yml

  tasks:
    - name: Copy NodeGroup manifest
      template:
        src: ../templates/nodegroup-{{ node_role }}.yaml.j2
        dest: /root/{{ node_role }}.yaml

    - name: Apply NodeGroup
      shell: kubectl apply -f /root/{{ node_role }}.yaml

    - name: Fetch bootstrap script secret
      shell: |
        kubectl -n d8-cloud-instance-manager get secret manual-bootstrap-for-{{ node_role }} -o json | jq -r '.data."bootstrap.sh"' > /root/{{ node_role }}.b64

    - name: Decode bootstrap.sh
      shell: |
        base64 -d /root/{{ node_role }}.b64 > /root/{{ node_role }}.sh && chmod +x /root/{{ node_role }}.sh

    - name: Send and execute bootstrap script on nodes
      delegate_to: "{{ hostvars[item].ansible_host }}"
      become: true
      copy:
        src: /root/{{ node_role }}.sh
        dest: /tmp/bootstrap.sh
        mode: 0755
      loop: "{{ groups['cluster'] | difference(['master']) | select('match', node_role) | list }}"

    - name: Run bootstrap.sh on remote node
      delegate_to: "{{ hostvars[item].ansible_host }}"
      become: true
      shell: /tmp/bootstrap.sh
      loop: "{{ groups['cluster'] | difference(['master']) | select('match', node_role) | list }}"
EOF

echo "✅ Проект готов: $PROJECT_DIR"
echo "💡 Используй:"
echo "   cd $PROJECT_DIR"
echo "   ansible-playbook -i inventory/hosts.yml playbooks/bootstrap.yml --ask-vault-pass"
echo "   ansible-playbook -i inventory/hosts.yml playbooks/add_nodegroup.yml --extra-vars node_role=system --ask-vault-pass"
echo "   ansible-playbook -i inventory/hosts.yml playbooks/add_nodegroup.yml --extra-vars node_role=worker --ask-vault-pass"
