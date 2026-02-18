# Define a new custom role with the required permissions
$role = Get-AzRoleDefinition Contributor
$role.Id = $null # Set ID to null to define a new role
$role.Name = "Bicep Deployment Creator"
$role.Description = "Can create ARM/Bicep deployments and role assignments"
$role.Actions.Clear() # Clear inherited permissions
$role.NotActions.Clear() # Clear inherited NotActions
$role.Actions.Add("Microsoft.Authorization/roleAssignments/write")
$role.Actions.Add("Microsoft.Resources/deployments/write")
$role.Actions.Add("Microsoft.Resources/deployments/read")
$role.Actions.Add("Microsoft.Resources/deployments/operationStatuses/read")
$role.Actions.Add("Microsoft.Resources/deployments/whatIf/action")
$role.AssignableScopes.Clear() # Clear existing scopes
$role.AssignableScopes.Add("/providers/Microsoft.Management/managementGroups/3974b8d0-f3ec-460f-b37f-179f29b49b6c") # Replace <subscriptionID> with your subscription ID

# Create the custom role definition
New-AzRoleDefinition -Role $role

# Verify the new role definition
Get-AzRoleDefinition -Name "Bicep Deployment Creator"