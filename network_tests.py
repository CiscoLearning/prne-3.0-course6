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
    
if __name__ == "__main__":
    get_device_info(r1)