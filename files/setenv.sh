# Public Fully Qualified Domain Name for the Controller
export TF_VAR_ctrl_fqdn=""
# Private IP Address of the Controller, so the instance can communicate locally
export TF_VAR_ctrl_ip=""
# API Key for the build of the controller agent on the instance
export TF_VAR_API_KEY=""
# Location of the instance in the controller. Should already be created.
export TF_VAR_location=""
# Email address of the administrator on the controller to log in to the controller (used for the API)
export TF_VAR_useremail=""
# Password of the administrator on the controller.
export TF_VAR_ctrlpassword=""
# Environment where the instance gateway will be created
export TF_VAR_ctrl_env=""
# Private Registry URL and path
export TF_VAR_PRIVATE_REGISTRY=registry.gitlab.com/path

