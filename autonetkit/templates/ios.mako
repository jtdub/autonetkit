! IOS Config generated by ${ank_version} on ${date} 
!
hostname ${node}
boot-start-marker
boot-end-marker
!
% if node.include_csr:
ip routing
license feature csr
!
!
% endif
no aaa new-model
!
!
ip cef
! 
!      
service timestamps debug datetime msec
service timestamps log datetime msec
no service password-encryption
enable password cisco
ip classless
ip subnet-zero
no ip domain lookup
line vty 0 4
 exec-timeout 720 0
 password cisco
 login
line con 0
 password cisco
!
## Physical Interfaces
% for interface in node.interfaces:  
interface ${interface.id}
  description ${interface.description}
  ip address ${interface.ipv4_address} ${interface.ipv4_subnet.netmask}   
  % if interface.ipv6_address:
  ipv6 address ${interface.ipv6_address} 
  %endif
  % if interface.ospf_cost:
  ip ospf network point-to-point
  ip ospf cost ${interface.ospf_cost}
  % endif
  % if interface.isis:
  ip router isis
    % if interface.physical:
  isis circuit-type level-2-only
  isis network point-to-point
  isis metric ${interface.isis_metric}
    % endif
  % endif
  duplex auto
  speed auto
  ##TODO: don't set speed/duplex for loopback interfaces
  no shutdown
!
% endfor 
!               
## OSPF
% if node.ospf: 
router ospf ${node.ospf.process_id} 
# Loopback
  network ${node.loopback} 0.0.0.0 area ${node.ospf.loopback_area}
  log-adjacency-changes
  passive-interface ${node.ospf.lo_interface}
% for ospf_link in node.ospf.ospf_links:
  network ${ospf_link.network.network} ${ospf_link.network.hostmask} area ${ospf_link.area} 
% endfor    
% endif           
## ISIS
% if node.isis: 
router isis ${node.isis.process_id}
  net ${node.isis.net}
  metric-style wide
% endif  
% if node.eigrp: 
router eigrp ${node.eigrp.process_id}       
% endif   
!                
## BGP
% if node.bgp: 
router bgp ${node.asn}   
  bgp router-id ${node.loopback}
  no synchronization
% for subnet in node.bgp.advertise_subnets:
  network ${subnet.network} mask ${subnet.netmask}
% endfor 
! ibgp
## iBGP Route Reflector Clients
% for client in node.bgp.ibgp_rr_clients:   
% if loop.first:
  ! ibgp clients
% endif    
  !
  neighbor ${client.loopback} remote-as ${client.asn}
  neighbor ${client.loopback} description rr client ${client.neighbor}
  neighbor ${client.loopback} update-source ${node.bgp.lo_interface} 
  neighbor ${client.loopback} route-reflector-client                                                   
  % if node.bgp.ebgp_neighbors: 
  neighbor ${client.loopback} next-hop-self
  % endif
% endfor            
## iBGP Route Reflectors (Parents)
% for parent in node.bgp.ibgp_rr_parents:   
% if loop.first:
  ! ibgp route reflector servers
% endif    
  !
  neighbor ${parent.loopback} remote-as ${parent.asn}
  neighbor ${parent.loopback} description rr parent ${parent.neighbor}
  neighbor ${parent.loopback} update-source ${node.bgp.lo_interface} 
  % if node.bgp.ebgp_neighbors: 
  neighbor ${parent.loopback} next-hop-self
  % endif
% endfor
## iBGP peers
% for neigh in node.bgp.ibgp_neighbors:      
% if loop.first:
  ! ibgp peers
% endif 
  !
  neighbor ${neigh.loopback} remote-as ${neigh.asn}
  neighbor ${neigh.loopback} description iBGP peer ${neigh.neighbor}
  neighbor ${neigh.loopback} update-source ${node.bgp.lo_interface}
  % if node.bgp.ebgp_neighbors: 
  neighbor ${neigh.loopback} next-hop-self
  % endif
% endfor
## eBGP peers
% for neigh in node.bgp.ebgp_neighbors:      
% if loop.first:
! ebgp
% endif
  !
  neighbor ${neigh.dst_int_ip} remote-as ${neigh.asn}
  neighbor ${neigh.dst_int_ip} description eBGP to ${neigh.neighbor}
  neighbor ${neigh.dst_int_ip} send-community
  neighbor ${neigh.dst_int_ip} next-hop-self
% endfor    
% endif 
!
end
