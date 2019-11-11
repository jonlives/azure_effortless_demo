# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "${var.azure_sub_id}"
    client_id       = "${var.azure_client_id}"
    client_secret   = "${var.azure_client_secret}"
    tenant_id       = "${var.azure_tenant_id}"
}

terraform {
  backend "azurerm" {
    resource_group_name  = "__TF_RESOURCE_GROUP_NAME__"
    storage_account_name = "__TF_STORAGE_ACCOUNT_NAME__"
    container_name       = "__TF_CONTAINER_NAME__"
    key                  = "__TF_KEY__"
  }
}

locals {
  custom_data_params  = "Param($ComputerName = \"effortlessvm\")"
  custom_data_content = "${local.custom_data_params} ${file("./files/winrm.ps1")}"
}

data "azurerm_image" "effortless-win2016" {
  name                = "__TF_MANAGED_IMAGE_NAME__"
  resource_group_name = "__TF_RESOURCE_GROUP_NAME__"
}

data "azurerm_image" "effortless-rhel-7" {
  name                = "__TF_MANAGED_IMAGE_NAME_RHEL__"
  resource_group_name = "__TF_RESOURCE_GROUP_NAME__"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "effortlessrg" {
    name     = "${var.tag_customer}_${var.tag_project}_rg"
    location = "${var.azure_region}"

    tags = {
        environment = "${var.tag_customer}_${var.tag_project}"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "effortlessnetwork" {
    name                = "${var.tag_customer}_${var.tag_project}_network"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.effortlessrg.name}"

    tags = {
        environment = "${var.tag_customer}_${var.tag_project}"
    }
}

# Create subnet
resource "azurerm_subnet" "effortlesssubnet" {
    name                 = "${var.tag_customer}_${var.tag_project}_subnet"
    resource_group_name  = "${azurerm_resource_group.effortlessrg.name}"
    virtual_network_name = "${azurerm_virtual_network.effortlessnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "effortlesspublicip" {
    name                         = "${var.tag_customer}_${var.tag_project}_ip"
    location                     = "${var.azure_region}"
    resource_group_name          = "${azurerm_resource_group.effortlessrg.name}"
    allocation_method            = "Dynamic"
    domain_name_label            = "effortless-${lower(substr("${join("", split(":", timestamp()))}", 8, -1))}"

    tags = {
        environment = "${var.tag_customer}_${var.tag_project}"
    }
}

# Create public IPs
resource "azurerm_public_ip" "effortlesspublicip_linux" {
    name                         = "${var.tag_customer}_${var.tag_project}_ip"
    location                     = "${var.azure_region}"
    resource_group_name          = "${azurerm_resource_group.effortlessrg.name}"
    allocation_method            = "Dynamic"
    domain_name_label            = "effortless-${lower(substr("${join("", split(":", timestamp()))}", 8, -1))}"

    tags = {
        environment = "${var.tag_customer}_${var.tag_project}"
    }
}

data "azurerm_public_ip" "effortlessip" {
  name                = "${azurerm_public_ip.effortlesspublicip.name}"
  resource_group_name = "${azurerm_resource_group.effortlessrg.name}"
}

data "azurerm_public_ip" "effortlessip_linux" {
  name                = "${azurerm_public_ip.effortlesspublicip_linux.name}"
  resource_group_name = "${azurerm_resource_group.effortlessrg.name}"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "effortlessnsg" {
    name                = "${var.tag_customer}_${var.tag_project}_sg"
    location            = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.effortlessrg.name}"
    
    security_rule {
        name                       = "RDP"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "WinRemoteMgmt"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3986"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "Allow_WinRM"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "5985"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "effortlessnsg_linux" {
    name                = "${var.tag_customer}_${var.tag_project}_sg"
    location            = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.effortlessrg.name}"
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Create network interface
resource "azurerm_network_interface" "effortlessnic" {
    name                      = "${var.tag_customer}_${var.tag_project}_nic"
    location                  = "${var.azure_region}"
    resource_group_name       = "${azurerm_resource_group.effortlessrg.name}"
    network_security_group_id = "${azurerm_network_security_group.effortlessnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.effortlesssubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.effortlesspublicip.id}"
    }

    tags = {
        environment = "${var.tag_customer}_${var.tag_project}"
    }
}

resource "azurerm_network_interface" "effortlessnic_linux" {
    name                      = "${var.tag_customer}_${var.tag_project}_nic_linux"
    location                  = "${var.azure_region}"
    resource_group_name       = "${azurerm_resource_group.effortlessrg.name}"
    network_security_group_id = "${azurerm_network_security_group.effortlessnsg_linux.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.effortlesssubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.effortlesspublicip_linux.id}"
    }

    tags = {
        environment = "${var.tag_customer}_${var.tag_project}"
    }
}


# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.effortlessrg.name}"
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "effortlessstorge" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.effortlessrg.name}"
    location                    = "${var.azure_region}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "${var.tag_customer}_${var.tag_project}"
    }
}


# Create virtual machine
resource "azurerm_virtual_machine" "effortlessvm" {
    name                  = "effortlessvm"
    location              = "${var.azure_region}"
    resource_group_name   = "${azurerm_resource_group.effortlessrg.name}"
    network_interface_ids = ["${azurerm_network_interface.effortlessnic.id}"]
    vm_size               = "Standard_E2s_v3"

    storage_os_disk {
        name              = "osdisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
      id = "${data.azurerm_image.effortless-win2016.id}"
    }


    os_profile {
        computer_name  = "effortless"
        admin_username = "${var.azure_image_user}"
        admin_password = "${var.azure_image_password}"
        custom_data    = "${local.custom_data_content}"
    }

    os_profile_windows_config {
        provision_vm_agent = true
        winrm {
            protocol = "http"
        }
        # Auto-Login's required to configure WinRM
        additional_unattend_config {
        pass         = "oobeSystem"
        component    = "Microsoft-Windows-Shell-Setup"
        setting_name = "AutoLogon"
        content      = "<AutoLogon><Password><Value>${var.azure_image_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.azure_image_user}</Username></AutoLogon>"
        }

        # Unattend config is to enable basic auth in WinRM, required for the provisioner stage.
        additional_unattend_config {
        pass         = "oobeSystem"
        component    = "Microsoft-Windows-Shell-Setup"
        setting_name = "FirstLogonCommands"
        content      = "${file("./files/FirstLogonCommands.xml")}"
        }
    }
    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.effortlessstorge.primary_blob_endpoint}"
    }

    tags = {
        environment = "${var.tag_customer}_${var.tag_project}"
    }


    connection {
        host     = "${azurerm_public_ip.effortlesspublicip.fqdn}"
        type     = "winrm"
        port     = 5985
        https    = false
        timeout  = "2m"
        user     = "${var.azure_image_user}"
        password = "${var.azure_image_password}"
    }
    provisioner "file" {
        source      = "./files/hab_config.toml"
        destination = "C:/tmp/hab_config.toml"
    }

    provisioner "file" {
        source      = "./files/config_patch.ps1"
        destination = "C:/tmp/config_patch.ps1"
    }
    provisioner "remote-exec" {
    inline = [
      "powershell.exe C:/tmp/config_patch.ps1"
    ]
  }
}

resource "azurerm_virtual_machine_extension" "enable_effortless_audit" {
  name                 = "CustomScriptExtension"
  location             = "${var.azure_region}"
  resource_group_name  = "${azurerm_resource_group.effortlessrg.name}"
  virtual_machine_name = "${azurerm_virtual_machine.effortlessvm.name}"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.4"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe C:/ProgramData/chocolatey/bin/hab svc load effortless/audit-baseline --strategy at-once && powershell.exe C:/ProgramData/chocolatey/bin/hab svc load effortless/config-baseline --strategy at-once && C:/ProgramData/chocolatey/bin/hab config apply config-baseline.default 2 C:/tmp/hab_config.toml && C:/ProgramData/chocolatey/bin/hab config apply audit-baseline.default 2 C:/tmp/hab_config.toml"
    }
SETTINGS
}

resource "azurerm_virtual_machine" "effortlessvm-rhel" {
    name                  = "effortlessvm-rhel"
    location              = "${var.azure_region}"
    resource_group_name   = "${azurerm_resource_group.effortlessrg.name}"
    network_interface_ids = ["${azurerm_network_interface.effortlessnic_linux.id}"]
    vm_size               = "Standard_E2s_v3"

  # This means the OS Disk will be deleted when Terraform destroys the Virtual Machine
  # NOTE: This may not be optimal in all cases.
  delete_os_disk_on_termination = true

    storage_os_disk {
        name              = "osdisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
      id = "${data.azurerm_image.effortless-rhel-7.id}"
    }


    os_profile {
        computer_name  = "effortless-rhel7"
        admin_username = "${var.azure_image_user}"
        admin_password = "${var.azure_image_password}"
    }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  connection {
      host     = "${azurerm_public_ip.effortlesspublicip_linux.fqdn}"
      user     = "${var.azure_image_user}"
      password = "${var.azure_image_password}"
  }
  provisioner "file" {
        source      = "./files/hab_config.toml"
        destination = "/tmp/hab_config.toml"
  }
  provisioner "remote-exec" {
    inline = [
      "hab svc load effortless/audit-baseline --strategy at-once",
      "hab svc load effortless/config-baseline --strategy at-once",
      "hab config apply config-baseline.default 2 /tmp/hab_config.toml",
      "hab config apply audit-baseline.default 2 /tmp/hab_config.toml"
    ]
  }
}