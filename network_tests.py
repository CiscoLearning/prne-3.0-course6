from genie.testbed import load

testbed = load("testbed.yaml")
r1 = testbed.devices['R1']

def get_device_info(device):
    device.connect(log_stdout=False)
    output = device.parse("show version")
    os_version = output['version']['version']
    uptime = output['version']['uptime']
    print(f"  OS Version: {os_version}")
    print(f"  Uptime: {uptime}")

def check_ospf_neighbors(device):
    device.connect(log_stdout=False)
    try:
        output = device.parse("show ip ospf neighbor") 
    except:
        print(f"No OSPF Neigbors on {device.name}")
        return
    print(output)
    ospf_neighbors = output["interfaces"]
    for interface, neighbors in ospf_neighbors.items():
        for neighbor_ip, neighbor_info in neighbors["neighbors"].items():
            state = neighbor_info["state"]
            print(f"Neighbor: {neighbor_ip}, State: {state}")

def check_acl(device):
    config_data = device.execute("show running-config | include access-list")
    if "server_access" in config_data:
        print(" Access List Configured  ")  
        print("PASS")  
    else:
        print(" Access List Not Configured  ")
        print("FAIL")

if __name__ == "__main__":
    get_device_info(r1)
    check_ospf_neighbors(r1)
    check_acl(r1)