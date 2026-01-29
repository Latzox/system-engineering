function New-AzureProject {
    <#
        .SYNOPSIS
        Automates the setup and configuration of a new Azure project such as ACI with ACR integration and GitHub federated identity for secure CI/CD workflows.

        .DESCRIPTION
        This script performs the following:
        - Creates an Azure AD Service Principal for authentication.
        - Configures GitHub federated identity with Azure AD for seamless CI/CD.
        - Assigns necessary Azure RBAC roles for ACI and ACR operations.
        - Configures GitHub repository secrets for secure authentication.

        .PARAMETER DisplayName
        The display name for the Azure AD Service Principal.

        .PARAMETER DockerImageName
        The name of the Docker image for deployment.

        .PARAMETER AciSubscriptionId
        The subscription ID where the ACI will be deployed.

        .PARAMETER AcrSubscriptionId
        The subscription ID for the Azure Container Registry.

        .PARAMETER AcrResourceGroup
        The resource group name for the Azure Container Registry.

        .PARAMETER AcrName
        The name of the Azure Container Registry.

        .PARAMETER GitHubOrg
        The GitHub organization name.

        .PARAMETER RepoName
        The GitHub repository name for storing deployment manifests.

        .PARAMETER EnvironmentNames
        The list of environment names for GitHub workflows.

        .INPUTS
        None. This script does not accept piped input.

        .OUTPUTS
        None. This script outputs verbose information to the console during execution.

        .EXAMPLE
        PS> New-AzureProject -DisplayName "Quickstart ACI API Development" `
                -DockerImageName "quickstart-aci-dev-api" `
                -AciSubscriptionId "<SubscriptionID>" `
                -AcrSubscriptionId "<SubscriptionID>" `
                -AcrResourceGroup "rg-acr-prod-001" `
                -AcrName "latzox" `
                -GitHubOrg "Latzox" `
                -RepoName "quickstart-api-development-with-aci" `
                -EnvironmentNames @('build', 'infra')

        .NOTES
        Author: Latzox
        Date: 31-12-2024
        Version: 1.2

        .LINK
        https://github.com/Latzox/quickstart-api-development-with-aci
    #>

    param (
        # Service Principal Parameters
        [Parameter(Mandatory = $true, HelpMessage = "Display name for the Entra ID Service Principal.")]
        [string]$DisplayName,

        # ACI Parameters
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Docker image for deployment.")]
        [string]$DockerImageName,

        [Parameter(Mandatory = $true, HelpMessage = "The subscription ID for the Azure Container Instance.")]
        [ValidateNotNullOrEmpty()]
        [string]$AciSubscriptionId,

        # ACR Parameters
        [Parameter(Mandatory = $true, HelpMessage = "The subscription ID for the Azure Container Registry.")]
        [ValidateNotNullOrEmpty()]
        [string]$AcrSubscriptionId,

        [Parameter(Mandatory = $true, HelpMessage = "The resource group name for the Azure Container Registry.")]
        [ValidateNotNullOrEmpty()]
        [string]$AcrResourceGroup,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Container Registry.")]
        [ValidateNotNullOrEmpty()]
        [string]$AcrName,

        [Parameter(Mandatory = $true, HelpMessage = "The password of the Azure Container Registry.")]
        [ValidateNotNullOrEmpty()]
        [SecureString]$AcrPassword,

        # GitHub Parameters
        [Parameter(Mandatory = $true, HelpMessage = "The GitHub organization name.")]
        [ValidateNotNullOrEmpty()]
        [string]$GitHubOrg,

        [Parameter(Mandatory = $true, HelpMessage = "The GitHub repository name.")]
        [ValidateNotNullOrEmpty()]
        [string]$RepoName,

        [Parameter(Mandatory = $true, HelpMessage = "List of environment names for GitHub workflows. For example: @('aks-prod', 'build', 'infra-preview', 'infra-prod')")]
        [ValidateNotNullOrEmpty()]
        [string[]]$EnvironmentNames
    )

    Begin {

        # Global settings
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        # Helper function to set the subscription context
        function Select-SubscriptionContext {
            param (
                [string]$SubscriptionId
            )
            Write-Verbose "Selecting subscription context for '$SubscriptionId'..."
            try {
                Select-AzSubscription -SubscriptionId $SubscriptionId
                Write-Verbose "Successfully set subscription context to '$SubscriptionId'."
            } catch {
                Write-Error "Failed to set subscription context: $_"
                exit 1
            }
        }
    }

    Process {
        # Step 1: Create Azure AD Service Principal
        try {
            Write-Verbose "Checking for existing Azure AD Service Principal..."
            $existingSp = Get-AzADServicePrincipal -DisplayName $DisplayName -ErrorAction SilentlyContinue

            if (-not $existingSp) {
                $sp = New-AzADServicePrincipal -DisplayName $DisplayName -Role "Contributor" -Scope "/subscriptions/$AciSubscriptionId"
                Write-Verbose "Service Principal created successfully. AppId: $($sp.AppId)"
            } else {
                $sp = $existingSp
                Write-Verbose "Service Principal already exists. AppId: $($sp.AppId)"
            }
        } catch {
            Write-Error "Failed to create or verify the Service Principal: $_"
            exit 1
        }

        # Step 2: Configure Federated Identity Credentials for GitHub Actions
        try {
            Write-Verbose "Checking and creating Federated Identity Credentials for GitHub Actions..."

            # Ensure EnvironmentNames is provided as an array
            if (-not ($EnvironmentNames -is [System.Array])) {
                Write-Error "EnvironmentNames must be an array of environment names."
                exit 1
            }

            foreach ($envName in $EnvironmentNames) {
                Write-Verbose "Processing environment: $envName"

                # Check if the federated credential already exists for this environment
                $existingCredential = Get-AzADAppFederatedCredential -ApplicationObjectId (Get-AzADApplication -DisplayName $DisplayName).Id -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -eq "OIDC-$envName" }

                if (-not $existingCredential) {
                    Write-Verbose "Creating Federated Identity Credential for environment '$envName'..."
                    $params = @{
                        ApplicationObjectId = (Get-AzADApplication -DisplayName $DisplayName).Id
                        Audience = "api://AzureADTokenExchange"
                        Issuer = "https://token.actions.githubusercontent.com"
                        Name = "OIDC-$envName"
                        Subject = "repo:$GitHubOrg/$($RepoName):environment:$($envName)"
                    }
                    New-AzADAppFederatedCredential @params
                    Write-Verbose "Federated Identity Credential for environment '$envName' configured successfully."
                } else {
                    Write-Verbose "Federated Identity Credential for environment '$envName' already exists."
                }
            }
        } catch {
            Write-Error "Failed to create or verify Federated Identity Credentials: $_"
            exit 1
        }

        # Step 3: Assign Roles for ACR
        Select-SubscriptionContext -SubscriptionId $AcrSubscriptionId
        try {
            Write-Verbose "Checking and assigning roles for ACR access..."

            # Check and assign the "AcrPush" role
            $acrPushExists = Get-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "AcrPush" `
                -Scope "/subscriptions/$AcrSubscriptionId/resourceGroups/$AcrResourceGroup/providers/Microsoft.ContainerRegistry/registries/$AcrName" `
                -ErrorAction SilentlyContinue

            if (-not $acrPushExists) {
                New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "AcrPush" `
                    -Scope "/subscriptions/$AcrSubscriptionId/resourceGroups/$AcrResourceGroup/providers/Microsoft.ContainerRegistry/registries/$AcrName"
                Write-Verbose "'AcrPush' role assigned successfully."
            } else {
                Write-Verbose "'AcrPush' role already assigned."
            }
        } catch {
            Write-Error "Failed to assign roles: $_"
            exit 1
        }

        # Step 4: Create the GitHub Actions Secrets
        try {
            Write-Verbose "Creating or verifying GitHub Actions Secrets..."

            # Define the secrets and their values
            $secrets = @{
                "ENTRA_CLIENT_ID"           = $sp.AppId
                "ENTRA_SUBSCRIPTION_ID"     = $AciSubscriptionId
                "ENTRA_TENANT_ID"           = (Get-AzContext).Tenant.Id
                "AZURE_ACR_NAME"            = $AcrName
                "AZURE_ACR_PASSWORD"        = ConvertFrom-SecureString $AcrPassword
                "DOCKER_IMAGE_NAME"         = $DockerImageName
            }

            foreach ($secretName in $secrets.Keys) {
                $secretValue = $secrets[$secretName]
                Write-Verbose "Creating or updating secret: $secretName"
                gh secret set $secretName --body $secretValue --repo "$($GitHubOrg)/$($RepoName)"
            }
            Write-Verbose "All secrets have been created or updated successfully."

        } catch {
            Write-Error "Failed to create or update secrets or variables in GitHub: $_"
            exit 1
        }
    }

    End {

        # Step 5: Cleanup - Remove autogenerated application secret
        Write-Verbose "Removing autogenerated application secrets..."
        try {
            Get-AzADAppCredential -DisplayName $sp.DisplayName | Remove-AzADAppCredential
        }
        catch {
            Write-Error "Failed to remove application secret: $_"
            exit 1
        }

        Write-Verbose "Script execution completed successfully!"
    }
}
