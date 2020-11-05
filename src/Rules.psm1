using namespace  System.Management.Automation.Language;
<#
    .DESCRIPTION
        Custom rule text when you call Invoke-Something.
#>  
function PesterScriptBlocksForV5Compat {

    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst,
        [string] $ScriptFilePath
    )

    Begin {
        $PesterBlockCommands = "Describe", "Context","InPesterModuleScope"
        $PesterRunCommands = "BeforeAll", "BeforeEach", "BeforeDiscovery", "AfterAll", "AfterEach", "InModuleScope", "It"
        

        function get-FileLink([StatementAst]$Statement, $file) {
            return "$($Statement.Extent.File)`:$($Statement.Extent.StartLineNumber)`:$($Statement.Extent.StartColumnNumber)"
        }

        function Find-BadBlocks {
            param($script, $file) 

            $blocks = $script.FindAll( { param ($i) return ($i -is [NamedBlockAst]) }, $false)
            foreach ( $o in $blocks ) {
                ##find all statements in a block, each should be a command Ast with command of a pester command

                #We navigate the statements as using Find results in finding items within command calls
                foreach ($statement in $o.statements) {
                    $bad = ""
                    if ($statement -isNot [PipelineAst] ) {
                        #All Pester statements are Pipelines
                        $bad = "Code found outside of Pester Block $statement"   
                    }
                    elseif ( $statement.PipelineElements[0] -isnot [CommandAst]) {
                        #The item in the pipeline needs to be a Command, expressions and other things aren't valid pester
                        $bad = "Code found outside of Pester Block $statement"   
                    }
                    else {
                        
                        $command = $statement.PipelineElements[0].CommandElements
                        if ($null -eq $Command) {
                            Write-Verbose "Should definitely not get here"
                        }
                        if ($PesterBlockCommands -contains $Command[0].Value ) {
                            Write-Verbose "Found Command $($Command[0])"
                            #We are using this rather than find otherwise scripts for ForEach or other parameter values are incorrectly identified
                            $scripts = $command | Where-Object { $_ -is [ScriptBlockExpressionAst] }
                            if ($scripts.Length -gt 1 ) {
                                Throw "should only have 1 script in a describe block"
                            }  
                            else {
                                #Check child blocks
                                Find-BadBlocks $scripts[0].ScriptBlock $File
                            }
                        } 
                        elseif ($PesterRunCommands -notContains $Command[0].Value ) {

                            $bad = "Code found outside of Pester Block $statement"
         
                        }
                    }
                    if ($bad -ne "") {
                        $message = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                            Message    = $bad
                            ; Extent   = $statement.Extent
                            ; RuleName = $PSCmdlet.MyInvocation.InvocationName
                            ; Severity = "Warning" 
                        }
                        Write-Output $message
                    }
                }

            }
        }
    }

    Process {
        Try {
            #it seems VSCode runs this on fragments, if we dont do this it slows stuff down and we only need to check the global content
            #We possibly could work at a fragment level to see if its valid
            if ($null -eq $ScriptBlockAst.Parent.Parent) {
                #Check for Pester
                $Pester = $ScriptBlockAst.Find( { param ($command) $command -is [CommandAst] -and ([commandAst]$command).CommandElements[0].Value -eq "Describe" }, $true)

                if ($null -ne $Pester) {
                    Find-BadBlocks $ScriptBlockAst
                }
            }
        }
        catch {
    
            $PSCmdlet.ThrowTerminatingError( $_ )
    
        }
    }
}


Export-ModuleMember -Function PesterScriptBlocksForV5Compat