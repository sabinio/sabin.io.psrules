
Describe "AllTests" {
    BeforeAll {
        import-module $PSScriptRoot\Rules.psm1 -Force
    
    }
    Describe "TestKnown script" {
        It "Should produce warnings" {
            $script = { 
                $foo ;
                ###sdfsdfs
                Describe "sdfs" { 
                    $foo = 999;
                    Context "" {
                        $foo = 100
                        It "simon" {
                            $foo | Should -be 100 }
                    }
                    $fofdfd = 100
                    Call-Simon
                }
            }
            $rules = PesterScriptBlocksForV5Compat $script.Ast
        }
    }

    Describe "Test script without Pester" {
        It "Should produce not produce warnings" {
    
            $script = [ScriptBlock]::Create('
            $foo ;
            ###sdfsdfs
            $foo = 999;
        ')
            (PesterScriptBlocksForV5Compat $script.Ast).Count | Should -be 0
        }
    }

    Describe "Test script with Pester" {
        It "Should produce warnings in outside of a Describe" {
            $script = [ScriptBlock]::Create('
         $foo=100
            Describe "fgdf"{
            }
        
        ')
            $Errors = PesterScriptBlocksForV5Compat $script.Ast
            $Errors.Count | Should -be 1 "Should find one error"
      
            $Errors[0].Extent.StartLineNumber | Should -be 2 "Problem starts on Line 2"
            $Errors[0].Extent.EndLineNumber | Should -be 2 "Problem ends on Line 2"
        }

        It "Should produce warnings in outside of a Describe" {
            $script = [ScriptBlock]::Create('
            Describe "fgdf"{
                $foo=100
            }
        
        ')
            $Errors = PesterScriptBlocksForV5Compat $script.Ast
            $Errors.Count | Should -be 1
            $Errors[0].Extent.StartLineNumber | Should -be 3 "Problem starts on Line 3"
            $Errors[0].Extent.EndLineNumber | Should -be 3 "Problem ends on Line 3"
        }
    
        It "Should produce warnings in outside of a Describe" {
            $script = [ScriptBlock]::Create('
            Describe ""{
                Context "fgdf"{
                $foo=100
            }
        }
        ')
            $Errors = PesterScriptBlocksForV5Compat $script.Ast
            $Errors.Count | Should -be 1
            $Errors[0].Extent.StartLineNumber | Should -be 4 "Problem starts on Line 4"
            $Errors[0].Extent.EndLineNumber | Should -be 4 "Problem ends on Line 4"
        }
    
        It "Should produce ignore comments" {
    
            $script = [ScriptBlock]::Create('
            ###sdfsdfs
            Describe "fgdf"{  ###sdfsdfs
           
            Context "" { ###sdfsdfs
           
                It "simon" {
                    ###sdfsdfs
           
                    $foo | Should -be 100 }
            }
        } 
        ###sdfsdfs
        <# another comment #>
        ')
            $Results = PesterScriptBlocksForV5Compat $script.Ast
            $results.Count | Should -be 0
        }
    }
    Describe "Check Pester allowed" {
    
        It "Should produce ignore comments" {
    
            $script = [ScriptBlock]::Create("
InPesterModuleScope {
    Describe 'Find-File' {}
        }
            ")
            (PesterScriptBlocksForV5Compat $script.Ast).Count | Should -be 0
        }
    }

    Describe "Problem Records" {
    
        It "Should have messages" {

            $script = [ScriptBlock]::Create("
        `$foo=100
Describe 'Find-File' {}
    
        ")
            $Problems = PesterScriptBlocksForV5Compat $script.Ast
            $Problems.Count | Should -be 1
            $Problems[0].Message | Should -not -be ""
        }
    }

    Describe "Multiple Lines" {
    
        It "Should Output One Warning" {

            $script = [ScriptBlock]::Create('
$foo=100
$foo=99
Describe "Find-File" {}
    
        ')
            $errors = (PesterScriptBlocksForV5Compat $script.Ast)
            $errors.Count | Should -be 1
            $errors[0].Extent.StartLineNumber | should -be 2
            $errors[0].Extent.EndLineNumber | should -be 3
            $errors[0].SuggestedCorrections.Count | should -be 1
         
        }
    
        It "Should handle blocks in blocks" {

            $script = [ScriptBlock]::Create('
$foo=100
$foo=99
Describe "Find-File" {
    $foo=100
$foo=99
}
    
        ')
            $errors = (PesterScriptBlocksForV5Compat $script.Ast) 

            $errors.Count | Should -be 2
            ($errors | Where-Object { $_.Extent.StartLineNumber -eq 2 -and $_.Extent.EndLineNumber -eq 3 } ).Count | should -be 1
            ($errors | Where-Object { $_.Extent.StartLineNumber -eq 5 -and $_.Extent.EndLineNumber -eq 6 } ).Count | should -be 1
         
        }
    
        It "Should handle blocks in blocks" {

            $script = [ScriptBlock]::Create('
$foo=100
$foo=99
Describe "Find-File" {
    $foo=100
$foo=99
}
$bob=100
Get-Command
        ')
            $errors = (PesterScriptBlocksForV5Compat $script.Ast) 
            write-host ($errors | % { [PsCustomObject]@{RuleName = $_.RuleName; text = $_.Extent.Text; message = $_.Message; start = $_.Extent.StartLineNumber; end = $_.Extent.EndLineNumber } } | ft RuleName, Start, End, Message, Text | out-string)
            $errors.Count | Should -be 3
            ($errors | Where-Object { $_.Extent.StartLineNumber -eq 2 -and $_.Extent.EndLineNumber -eq 3 } ).Count | should -be 1
            ($errors | Where-Object { $_.Extent.StartLineNumber -eq 5 -and $_.Extent.EndLineNumber -eq 6 } ).Count | should -be 1
            ($errors | Where-Object { $_.Extent.StartLineNumber -eq 8 -and $_.Extent.EndLineNumber -eq 9 } ).Count | should -be 1
         
        }
    }
}