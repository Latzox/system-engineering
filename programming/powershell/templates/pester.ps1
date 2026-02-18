Describe '<FunctionName>' {

    BeforeAll {
        # Import the module or script containing the function to test
        # This is optional, depending on where your function is located
        Import-Module -Name "<YourModuleName>" -ErrorAction Stop
        # . "$PSScriptRoot\<YourScript.ps1>"  # If it's a script, dot-source it.
    }

    BeforeEach {
        # Run before each test
    }
    
    # Test Case: Test valid input and expected output
    It 'Should return expected output for valid input' {
        # Arrange: Setup any preconditions and inputs
        $input = "<ValidInput>"
        $expectedOutput = "<ExpectedOutput>"
        
        # Act: Call the function
        $result = <FunctionName> -Parameter1 $input
        
        # Assert: Compare actual and expected outputs
        $result | Should -Be $expectedOutput
    }
    
    # Test Case: Test when input is null or empty
    It 'Should handle null or empty input' {
        # Arrange
        $input = $null
        $expectedOutput = "<ExpectedNullOutput>"
        
        # Act
        $result = <FunctionName> -Parameter1 $input
        
        # Assert
        $result | Should -Be $expectedOutput
    }

    # Test Case: Test if an exception is thrown for invalid input
    It 'Should throw an error for invalid input' {
        # Arrange
        $invalidInput = "<InvalidInput>"
        
        # Act & Assert: Use ShouldThrow to catch exceptions
        { <FunctionName> -Parameter1 $invalidInput } | Should -Throw
    }
    
    # Test Case: Test side effects or function changes state
    It 'Should perform a side-effect or state change' {
        # Arrange
        $initialState = "<InitialState>"
        $expectedState = "<ExpectedState>"
        
        # Act
        <FunctionName> -Parameter1 $initialState
        
        # Assert: Verify the side effect
        <Get-StateFunction> | Should -Be $expectedState
    }
    
    # Test Case: Verify output is of correct type
    It 'Should return correct type for output' {
        # Arrange
        $input = "<ValidInput>"
        
        # Act
        $result = <FunctionName> -Parameter1 $input
        
        # Assert: Validate the type of the result
        $result | Should -BeOfType [<ExpectedType>]
    }
}
