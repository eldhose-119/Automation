---
cidr_networks:
  management: 172.29.236.0/22
  tunnel: 172.29.240.0/22
  storage: 172.29.244.0/22

global_overrides:
  external_lb_vip_address: ${controllers[0]}
  internal_lb_vip_address: ${controllers[1]}
  management_bridge: "br-mgmt"
  haproxy_keepalived_internal_interface: br-mgmt
  provider_networks:
    - network:
        container_bridge: "br-mgmt"
        container_type: "veth"
        container_interface: "eth1"
        ip_from_q: "management"
        type: "raw"
        group_binds:
          - all_containers
          - hosts
        is_management_address: true
    - network:
        container_bridge: "br-vxlan"
        container_type: "veth"
        container_interface: "eth10"
        ip_from_q: "tunnel"
        type: "vxlan"
        range: "1:1000"
        net_name: "vxlan"
        group_binds:
          - neutron_openvswitch_agent
    - network:
        container_bridge: "br-storage"
        container_type: "veth"
        container_interface: "eth2"
        ip_from_q: "storage"
        type: "raw"
        group_binds:
          - glance_api
          - cinder_api
          - cinder_volume
          - nova_compute

shared-infra_hosts:
%{ for idx, ip in controllers ~}
  controller-${idx + 1}:
    ip: ${ip}
%{ endfor ~}

compute_hosts:
%{ for idx, ip in computes ~}
  compute-${idx + 1}:
    ip: ${ip}
%{ endfor ~}

storage_hosts:
%{ for idx, ip in storages ~}
  storage-${idx + 1}:
    ip: ${ip}
%{ endfor ~}
