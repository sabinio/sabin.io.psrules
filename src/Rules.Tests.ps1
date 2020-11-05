
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
        $Errors =     PesterScriptBlocksForV5Compat $script.Ast
        $Errors.Count | Should -be 1
        $Errors[0].Extent.Text | Should -be '$foo=100'
    }

    It "Should produce warnings in outside of a Describe" {
        $script = [ScriptBlock]::Create('
            Describe "fgdf"{
                $foo=100
            }
        
        ')
        $Errors =     PesterScriptBlocksForV5Compat $script.Ast
        $Errors.Count | Should -be 1
        $Errors[0].Extent.Text | Should -be '$foo=100'
    }
    
    It "Should produce warnings in outside of a Describe" {
        $script = [ScriptBlock]::Create('
            Describe ""{
                Context "fgdf"{
                $foo=100
            }
        }
        ')
        $Errors =     PesterScriptBlocksForV5Compat $script.Ast
        $Errors.Count | Should -be 1
        $Errors[0].Extent.Text | Should -be '$foo=100'
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
        (PesterScriptBlocksForV5Compat $script.Ast).Count | Should -be 0
    }
}