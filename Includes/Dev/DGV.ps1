Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Out-DataTable { 
    # based on http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx

    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject[]]$InputObject
    )

    begin { 
        $DataTable = [Data.DataTable]::new()
        $First = $true
    }
    process { 
        foreach ($Object in $InputObject) { 
            $DataRow = $DataTable.NewRow()
            foreach ($Property in $Object.PSObject.Properties) { 
                if ($First) { 
                    $Col = [Data.DataColumn]::.new()
                    $Col.ColumnName = $Property.Name.ToString()
                    $DataTable.Columns.Add($Col)
                }
                $DataRow.Item($Property.Name) = $Property.Value
            }
            $DataTable.Rows.Add($DataRow)
            $First = $false
        }
    }
    end { 
        return @(, $DataTable)
    }
}

# Sample Data (Replace with your actual data source)
$data = @(
    @{ Column1 = "ValueA"; Column2 = "ValueX"; Column3 = "Value1" }
    @{ Column1 = "ValueB"; Column2 = "ValueY"; Column3 = "Value2" }
    @{ Column1 = "ValueC"; Column2 = "ValueZ"; Column3 = "Value3" }
    @{ Column1 = "ValueA"; Column2 = "ValueY"; Column3 = "Value1" }
)

# Create Form and DataGridView
$form = [System.Windows.Forms.Form]::new()
$form.Text = "DataGridView with ComboBox Row"
$form.Size = [System.Drawing.Size]::new(800, 600)

$dataGridView = [System.Windows.Forms.DataGridView]::new()
$dataGridView.Dock = "Fill"

# Add Data to DataGridView
$dataGridView.DataSource = $data  #| Out-GridView

# Ensure DataGridView is populated before proceeding
$form.Controls.Add($dataGridView)
$form.Show() # Show form to populate DataGridView, then hide it again
$form.Hide()

# Create ComboBox Row
# $comboBoxRow = $dataGridView.Rows.Insert(1) # Insert below header row (index 1)


# Populate ComboBoxes in the new row
for ($colIndex = 0; $colIndex -lt $dataGridView.Columns.Count; $colIndex++) { 
    $columnName = $dataGridView.Columns[$colIndex].Name

    # Extract unique values from the data for the current column
    $comboBoxValues = $data | Select-Object -ExpandProperty $columnName -Unique

    # Create ComboBox Cell
    $comboBoxCell = [System.Windows.Forms.DataGridViewComboBoxCell]::new()
    $comboBoxCell.Items.AddRange($comboBoxValues)
    $comboBoxCell.DisplayStyle = "ComboBox" # Ensure it displays as a combobox, not just a dropdown arrow

    # Set the ComboBox Cell to the new row and correct column
    $dataGridView.Rows[$comboBoxRow].Cells[$colIndex] = $comboBoxCell
}

# Set the ComboBox row to be non-sortable and indicate it's a filter row (optional)
$dataGridView.Rows[$comboBoxRow].SortMode = "NotSortable"
$dataGridView.Rows[$comboBoxRow].HeaderCell.Value = "Filter" # Optional: Add "Filter" to the row header


# Show the Form with the DataGridView
$form.ShowDialog()