using namespace  System.Management.Automation.Language;

#import-module .\src\Rules.psm1 -force


$errors = Invoke-ScriptAnalyzer -Path '.\src\Sample.ps1' -CustomRulePath '.\src\rules.psm1' 

$errors | %{[PsCustomObject]@{RuleName=$_.RuleName;text=$_.Extent.Text;message=$_.Message}} | ft RuleName,  Message,Text


$extent =  [ScriptExtent]::new([ScriptPosition]::new("", 1,0, "simon`nsabin`nfoo bar`n")
        , [ScriptPosition]::new("", 3,3,  " `n "))