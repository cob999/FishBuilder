$global:msbuildCpuCount = 2 # TODO maybe set to a proportion of #NUMBER_OF_PROCESSORS#
$global:fishBuilderRootDirectory = ''
$global:vagrantDirectory = ''
$global:summary = @()
$global:buildType = ''
$global:success = $true
$global:startTimestamp = get-date
$global:sw = [Diagnostics.Stopwatch]::StartNew()
$global:branch = ''

function RestartVagrant
{
    write-host "Vagrant restart started"

    try
    {
        Push-Location
        cd $global:vagrantDirectory
        vagrant reload
        Write-Host "Pausing to let Solr come up" # here we really should be pinging to see when solr comes up rather than waiting
        Start-Sleep -s 15 # let Solr come up
        $global:summary += "Vagrant restarted"
    }
    finally
    {
        Pop-Location
    }
}

function HaltVagrant
{
    write-host "Vagrant halt started"

    try
    {
        Push-Location
        cd $global:vagrantDirectory
        vagrant halt
        $global:summary += "Vagrant halted"
    }
    finally
    {
        Pop-Location
    }
}

function ResetIis
{
    write-host "IIS reset started"
    iisreset.exe
    $global:summary += "IIS reset"
}

function BuildFullSolution
{
    RunMSBuildWithParametersAndAddToSummary("""VSSolution.sln"" /t:Build --% /p:RestorePackages=false`;MvcBuildViews=false")
}

function BuildConsoleApp1
{
    RunMSBuildWithParametersAndAddToSummary("./ConsoleApp1/ConsoleApp1.csproj /t:Build")
}

function BuildConsoleApp2
{
    RunMSBuildWithParametersAndAddToSummary("./ConsoleApp2/ConsoleApp2.csproj /t:Build")
}

function RunMSBuildWithParametersAndAddToSummary($parameters)
{
    # http://stackoverflow.com/questions/6604089/dynamically-generate-command-line-command-then-invoke-using-powershell

    $msbuildStopwatch = [Diagnostics.Stopwatch]::StartNew()
    Invoke-Expression "msbuild $global:fishBuilderRootDirectory\$parameters /m:$global:msbuildCpuCount" # use this version as we don't use array of strings for parameters
    $msbuildFailed = $LastExitCode -ne 0
    $msbuildStopwatch.Stop
    
    $duration = FormatStopWatchDuration($msbuildStopwatch)
    $msg = "MSBuild $parameters $duration"
    $global:summary += $msg
    if ($msbuildFailed) { $global:summary += "MSBuild reported errors"; $global:success = $false }
}

function FormatStopWatchDuration($sw)
{
    return $sw.Elapsed.Minutes.ToString("D2") + ":" + $sw.Elapsed.Seconds.ToString("D2")
}

function GetCurrentBranch
{
    try
    {
        Push-Location

        cd $global:fishBuilderRootDirectory\..
        $branch = (git branch) -split '[\r\n]' | Where-Object {$_.StartsWith('*') } | % {$_.SubString(2)}
        return $branch
    }
    finally
    {
        Pop-Location
    }
}

# Example of how to execute SQL in this case to drop databases
function DropDatabases
{
    $dropQuery = @'
ALTER DATABASE [TestDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [TestDatabase];
'@


    try
    {
        Push-Location
        Invoke-Sqlcmd -Query $dropQuery -ServerInstance "."
    }
    catch
    {
        $global:summary += "Drop databases failed";
        throw;
    }
    finally
    {
        Pop-Location
    }
}

function BuildAndTest($buildOption, $nunitMode, $restartVagrant, $restartIis, $testSuite)
{
    $global:summary += "Build option - " + $buildOption;
    $global:summary += "Test suite - " + $testSuite;

    if( $restartVagrant -eq "ON" )
    {
        RestartVagrant
    }

    if( $restartIis -eq "ON" )
    {
        ResetIis
    }

    Write-Host "At this point we would build the required proj/solution and run nunit for the test suite $testSuite" -foregroundcolor red -backgroundcolor yellow
}

$fish= @'
                            ,
                       /(  /:./\
                    ,_/:`-/::/::/\_ ,
                    |:|::/::/::/::;'( ,,
                    |:|:/::/::/:;'::,':(.( ,
                _,-'"HHHHH"""HHoo--.::::,-:(,----..._
            ,-"HHHb  "HHHHb  HHHHb   HHHoo-.::::::::::-.
          ,'   "HHHb  "HHHHb "HHHH   HHHHH  Hoo::::::::::.              _,.-::`.
        ,'      "HH`.  "HHHH  HHHHb  "HHHH  "HHHb`-:::::::.        _.-:::::::;'
       / ,-.        :   HHHH  "HHHH   HHHH   HHHH  Hoo::::;    _,-:::::::::;'
     ,'  `-'        :   HHHH   HHHH   "HHH   "HHH  "HHHH-:._,o:::::::::::;'
    /               :   HHHH __HHHP...........HHH   HHHF   HHH:::::::;:;'
   /_               ; _,-::::::.:::::::::::::''HH   HHH    "HH::::::::(
   (_"-.,          /  : :.::.:.::::::::::,d   HHH   "HH     HH::::::::::.
    (,-'          /    :.::.:::.::::::;'HHH   "HH    HH,::"-.H::::::::::::.
     ".         ,'    : :.:::.::::::;'  "HH    HH   _H-:::)   `-::::::::::::.
       `-.___,-'       `-.:::::,--'"     "H    HH,-::::::/        "--.::::::::.
            """---..__________________,-------'::::::::;/               """---'
                        \::.:---.          `::::::::::;'
                         \::::::|            `::;-'""
                          `.::::|
                            `.::|
                              `-'
'@

$crab= @'
               ___     ___
             .i .-'   `-. i.
           .'   `/     \'  _`.
           |,-../ o   o \.' `|
        (| |   /  _\ /_  \   | |)
         \\\  (_.'.'"`.`._)  ///
          \\`._(..:   :..)_.'//
           \`.__\ .:-:. /__.'/
            `-i-->.___.<--i-'
            .'.-'/.=^=.\`-.`.
           /.'  //     \\  `.\
          ||   ||       ||   ||
          \)   ||       ||  (/
               \)       (/
'@
                              

function TestingSubMenu
{
    $buildOption = "BuildSolution"
    $nunitMode = "CONSOLE"
    $restartVagrant = "OFF"
    $restartIis = "OFF"

    Do
    {
        Do
        {
            Clear-Host
            Write-Host $crab
            Write-Host "
            ----- DAVE THE TESTING CRAB -----

            1 = Run test suite 1
            2 = Run test suite 2

            ---------------------------------

            C = Cycle Build Option (currently $buildOption) 
            N = Toggle Nunit Mode (currently $nunitMode) 
            V = Toggle Vagrant restart (currently $restartVagrant) 
            W = Toggle IIS restart (currently $restartIis) 

            ---------------------------------            

            X = Return to main menu

            ---------------------------------
           
            "

            $choice1 = read-host -prompt "Select an option & press enter"
        } until ($choice1 -match '[12CcNnVvWwXx]')

        if ($choice1 -match '[Xx]')
        { 
            break
        }
        elseif ($choice1 -match '[Cc]')
        { 
            if( $buildOption -eq "BuildSolution" )
            {
                $buildOption = "BuildConsoleApp1"
            }
            elseif( $buildOption -eq "BuildConsoleApp1" )
            {
                $buildOption = "BuildConsoleApp2"
            }
            elseif( $buildOption -eq "BuildConsoleApp2" )
            {
                $buildOption = "NoBuildTestsOnly"
            }
            else
            {
                $buildOption = "BuildSolution"
            }
        }
        elseif ($choice1 -match '[Nn]')
        {
            if( $nunitMode -eq "CONSOLE" )
            {
                $nunitMode = "INTERACTIVE"
            }
            else
            {
                $nunitMode = "CONSOLE"
            }        
        }
        elseif ($choice1 -match '[Vv]')
        {
            if( $restartVagrant -eq "ON" )
            {
                $restartVagrant = "OFF"
            }
            else
            {
                $restartVagrant = "ON"
            }        
        }
        elseif ($choice1 -match '[Ww]')
        {
            if( $restartIis -eq "ON" )
            {
                $restartIis = "OFF"
            }
            else
            {
                $restartIis = "ON"
            }        
        }
        else
        {
            BeforeBuild($crab)
    
            try
            {
                Switch -regex ($choice1)
                {
                    [1] {BuildAndTest $buildOption $nunitMode $restartVagrant $restartIis "TestSuite1"}
                    [2] {BuildAndTest $buildOption $nunitMode $restartVagrant $restartIis "TestSuite2"}
                }

                $global:success = $true
            }
            catch [System.Net.WebException],[System.Exception]
            {
                Write-Host "Error"
                $global:success = $false
            }

            AfterBuild($crab)
        }
    } while (1 -eq 1)
}

function ExitIfNotAdmin
{
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )
    & {
        if (-Not $currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator ))
        {
            Write-Host "FishBuilder must be run as administrator.`n" -foregroundcolor red -backgroundcolor yellow
            Exit
        }
    }
}

function BeforeBuild($theFish)
{
    $global:success = $true
    $global:startTimestamp = get-date
    $global:sw = [Diagnostics.Stopwatch]::StartNew()
    $global:summary = @()
    $global:buildType = ''
    $global:branch = GetCurrentBranch

    Clear-Host
    Write-Host $theFish
    Write-Host "Build started"
}

function AfterBuild{
    $global:sw.Stop()

    $duration = FormatStopWatchDuration($global:sw)

    if($global:success)
    {
        Write-Host "`n"
        Write-Host $global:buildType -foregroundcolor yellow -backgroundcolor DarkGreen
        Write-Host "Branch name:" $global:branch -foregroundcolor yellow -backgroundcolor DarkGreen
        Write-Host "Started at:" $global:startTimestamp -foregroundcolor yellow -backgroundcolor DarkGreen
        Write-Host "Time taken:" $duration -foregroundcolor yellow -backgroundcolor DarkGreen
        Write-Host "Summary:" -foregroundcolor yellow -backgroundcolor DarkGreen
        $global:summary | foreach {
            Write-Host $_ -foregroundcolor yellow -backgroundcolor DarkGreen
        }        
    }
    else
    {
        Write-Host "`n"
        Write-Host $global:buildType -foregroundcolor yellow -backgroundcolor red
        Write-Host "Branch name:" $global:branch -foregroundcolor yellow -backgroundcolor red
        Write-Host "Started at:" $global:startTimestamp -foregroundcolor yellow -backgroundcolor red
        Write-Host "Time taken:" $duration -foregroundcolor yellow -backgroundcolor red
        Write-Host "Summary:" -foregroundcolor yellow -backgroundcolor red
        $global:summary | foreach {
            Write-Host $_ -foregroundcolor yellow -backgroundcolor red
        }        
    }

    Write-Host "`n"
    read-host -prompt "press enter to continue..."
}

# ************************************************************
# ********************* This is the start of scripts execution
# ************************************************************

ExitIfNotAdmin

if(Test-Path Env:FISHBUILDER_ROOT)
{
    $global:fishBuilderRootDirectory = (Get-ChildItem Env:FISHBUILDER_ROOT).Value
    $global:vagrantDirectory = $global:fishBuilderRootDirectory + "/../vagrant"
}
else
{
    Clear-Host
    Write-Host $fish
    Write-Host "
    Error: Missing environment variable FISHBUILDER_ROOT
    set with powershell like the following
    [Environment]::SetEnvironmentVariable(""FISHBUILDER_ROOT"", ""path"", ""User"")
    "
    Exit
}

Do
{
    Do
    {
        Clear-Host
        Write-Host $fish
        Write-Host "
        --- WELCOME TO FISHBUILDER ---

        S = Build Full Solution
        A = Quick Build (ConsoleApp1 only)
        B = Quick Build (ConsoleApp2 only)
        D = Database Reset
        I = IIS Reset
        V = Restart Vagrant
        H = Halt Vagrant

        ------------------------------

        T = Testing Sub-menu
        
        ------------------------------
        
        X = Exit
        
        ------------------------------

        "

        $choice1 = read-host -prompt "Select an option & press enter"
    } until ($choice1 -match '[SsAaBbDdIiVvHhTtXx]')

    if ($choice1 -match '[Tt]')
    { 
        TestingSubMenu
    }
    elseif ($choice1 -match '[Xx]')
    { 
        Exit
    }
    else
    {
        try
        {
            BeforeBuild($fish)

            Switch -regex ($choice1)
            {
                [Ss] {$global:buildType += "Build Full Solution"; BuildFullSolution}
                [Aa] {$global:buildType += "Quick Build"; BuildConsoleApp1}
                [Bb] {$global:buildType += "Quick Build"; BuildConsoleApp2}
                [Dd] {$global:buildType += "Drop Databases"; DropDatabases}
                [Ii] {$global:buildType += "IIS Reset"; ResetIis}
                [Vv] {$global:buildType += "Restart Vagrant"; RestartVagrant}
                [Hh] {$global:buildType += "Halt Vagrant"; HaltVagrant}
            }

            $global:success = $true
        }
        catch [System.Net.WebException],[System.Exception]
        {
            Write-Host "Error"
            $global:success = $false
        }

        AfterBuild($fish)
    }
} while (1 -eq 1)
