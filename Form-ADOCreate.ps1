#Form Controls are laid out vertically, typically label, control, label, label, control

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Create new AD User Object"
$objForm.Size = New-Object System.Drawing.Size(400,600) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$x=$objListBox.SelectedItem;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(200,530)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click({$x=$objListBox.SelectedItem;Evaluate-Form($objListBox.SelectedItem);})
$objForm.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(275,530)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$objLabelFirstName = New-Object System.Windows.Forms.Label
$objLabelFirstName.Location = New-Object System.Drawing.Size(10,20) 
$objLabelFirstName.Size = New-Object System.Drawing.Size(280,20) 
$objLabelFirstName.Text = "First Name:"
$objForm.Controls.Add($objLabelFirstName) 

$objTextBoxFirstName = New-Object System.Windows.Forms.TextBox
$objTextBoxFirstName.Location = New-Object System.Drawing.Size(10,40)
$objTextBoxFirstName.Size = New-Object System.Drawing.Size(150,10) 
$objTextBoxFirstName.Height = 20
$objForm.Controls.Add($objTextBoxFirstName)

$objLabelLastName = New-Object System.Windows.Forms.Label
$objLabelLastName.Location = New-Object System.Drawing.Size(10,65) 
$objLabelLastName.Size = New-Object System.Drawing.Size(280,20) 
$objLabelLastName.Text = "Last Name:"
$objForm.Controls.Add($objLabelLastName) 

$objTextBoxLastName = New-Object System.Windows.Forms.TextBox
$objTextBoxLastName.Location = New-Object System.Drawing.Size(10,85)
$objTextBoxLastName.Size = New-Object System.Drawing.Size(150,10) 
$objTextBoxLastName.Height = 20
$objForm.Controls.Add($objTextBoxLastName)

$objLabelDisplayName = New-Object System.Windows.Forms.Label
$objLabelDisplayName.Location = New-Object System.Drawing.Size(10,110) 
$objLabelDisplayName.Size = New-Object System.Drawing.Size(280,20) 
$objLabelDisplayName.Text = "Display Name:"
$objForm.Controls.Add($objLabelDisplayName) 

$objTextBoxDisplayName = New-Object System.Windows.Forms.TextBox
$objTextBoxDisplayName.Location = New-Object System.Drawing.Size(10,130)
$objTextBoxDisplayName.Size = New-Object System.Drawing.Size(200,10) 
$objTextBoxDisplayName.Height = 20
$objForm.Controls.Add($objTextBoxDisplayName)

$objLabelDescription = New-Object System.Windows.Forms.Label
$objLabelDescription.Location = New-Object System.Drawing.Size(10,155) 
$objLabelDescription.Size = New-Object System.Drawing.Size(280,20) 
$objLabelDescription.Text = "Description:"
$objForm.Controls.Add($objLabelDescription) 

$objTextBoxDescription = New-Object System.Windows.Forms.TextBox
$objTextBoxDescription.Location = New-Object System.Drawing.Size(10,175)
$objTextBoxDescription.Size = New-Object System.Drawing.Size(250,10) 
$objTextBoxDescription.Height = 20
$objForm.Controls.Add($objTextBoxDescription)

$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()