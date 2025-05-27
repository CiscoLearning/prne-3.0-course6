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

    ospf_neighbors = output["interfaces"]
    test_pass = False
    for interface, neighbors in ospf_neighbors.items():
        for neighbor_ip, neighbor_info in neighbors["neighbors"].items():
            state = neighbor_info["state"]
            print(f"Neighbor: {neighbor_ip}, State: {state}")
            if state == "FULL/BDR" or state == "FULL/DR":
                test_pass = True  
    if test_pass:
        print("PASS")
    else:
        print("FAIL")

if __name__ == "__main__":
    get_device_info(r1)
    check_ospf_neighbors(r1)