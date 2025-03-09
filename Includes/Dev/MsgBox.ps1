
function Show-YesNoMessageBoxWithTimeout($Message, $Title, $TimeoutSeconds = 10) {
    # Create a hidden window for timer events
    $HiddenWindow = New-Object System.Windows.Forms.Form -Hidden
    $HiddenWindow.Add_Shown({
      # Start the timer
      $Timer = New-Object System.Timers.Timer
      $Timer.Interval = ($TimeoutSeconds * 1000)
      $Timer.Elapsed += {
        # Close the message box if timeout occurs
        [System.Windows.Forms.Application]::ExitThread()
        $HiddenWindow.Close() 
      }
      $Timer.Start()
    })
  
    # Create the message box
    $Result = [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question, [System.Windows.Forms.MessageBoxDefaultButton]::Button1)
  
    # Stop the timer and close the hidden window
    $Timer.Stop()
    $HiddenWindow.Close()
  
    # Return the result (Yes or No)
    if ($Result -eq [System.Windows.Forms.DialogResult]::Yes) {
      return $true
    } else {
      return $false
    }
  }
  
  # Example usage
  if (Show-YesNoMessageBoxWithTimeout "Do you want to continue?", "Confirmation") {
    Write-Host "User clicked Yes"
  } else {
    Write-Host "User clicked No or timed out"
  }