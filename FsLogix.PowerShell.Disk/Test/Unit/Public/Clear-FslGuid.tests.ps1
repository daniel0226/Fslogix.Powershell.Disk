$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$funcType = Split-Path $here -Leaf
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$here = $here | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
. "$here\$funcType\$sut"

Describe $sut {
   
    Context -Name 'General tests' {
        BeforeEach {
            mock -CommandName remove-item -MockWith {} -Verifiable
        }
        it 'should throw' {
            {Clear-FslGuid -GuidPath 'C:\blah'} | should throw
        }
        it 'should not throw' {
            {Clear-FslGuid} | should not throw
        }
        it 'should not throw' {
            {Clear-FslGuid -GuidPath 'C:\programdata\FsLogix\FslGuid'} | should not throw
        }
    }
    context -name 'Test folder' {
        it 'Should be empty' {
            Clear-FslGuid
            $File_Contents = get-childitem 'C:\programdata\FsLogix\FslGuid'
            $File_Contents | should be $null
        }
    }
    
}