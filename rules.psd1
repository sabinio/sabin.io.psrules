# PSScriptAnalyzerSettings.psd1
# Settings for PSScriptAnalyzer invocation.
@{
   # ExcludeRules = @('PSUseDeclaredVarsMoreThanAssignments')
    ExcludeRules = @('PSAvoidTrailingWhitespace');
#    IncludeDefaultRules=$true
 

    CustomRulePath = "C:\Users\SimonSabin\source\repos\Sabin.io.PSRules\src\Rules.psm1"
    Severity=@('Error','Warning')
}