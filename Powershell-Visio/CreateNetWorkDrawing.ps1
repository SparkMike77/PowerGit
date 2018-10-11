# ----------------------------------------------------------------------------- 
# CreateNetWorkDrawing.ps1 
# ed wilson, msft, 12/30/2009 
# uses visio automation model to create a visio drawing. 
# 
# Basic Network Diagram is oriented landscape. Coordinates are different 
# HSG-1-12-10 
# ----------------------------------------------------------------------------- 
 
$application = New-Object -ComObject Visio.Application 
$application.visible = $false 
$documents = $application.Documents 
$document = $documents.Add("Basic Network Diagram.vst") 
$pages = $application.ActiveDocument.Pages 
$page = $pages.Item(1) 
 
$NetworkStencil = $application.Documents.Add("periph_m.vss") 
$ComputerStencil = $application.Documents.Add("Computers and Monitors.vss") 
$ConnectorStencil = $application.Documents.Add("Connectors.vss") 
$pc = $ComputerStencil.Masters.Item("PC") 
 
$shape1 = $page.Drop($pc, 11.0, 1.0)  
$shape1.Text = "Lower Right`r`nShape1" 
 
$shape2 = $page.Drop($pc, 2.2, 1.0)  
$shape2.Text = "Lower Left`r`nShape2" 
 
$shape3 = $page.Drop($pc, 11.0, 6.8)  
$shape3.Text = "Upper Right`r`nShape3" 
 
$shape4 = $page.Drop($pc, 2.2, 6.8)  
$shape4.Text = "Upper Left`r`nShape4" 
 
 
$etherNet = $NetworkStencil.Masters.Item("Ethernet") 
$shape5 = $page.Drop($etherNet,6.0,4.2) 
$shape5.Text = "center" 
 
$connector = $ConnectorStencil.Masters.item("Dynamic Connector") 
$shape1.AutoConnect($shape5, 0, $connector) 
$shape2.AutoConnect($shape5, 0, $connector) 
$shape3.AutoConnect($shape5, 0, $connector) 
$shape4.AutoConnect($shape5, 0, $connector) 
 
$page.CenterDrawing() 
$document.SaveAs("C:\fso\MyNetwork.vsd") 
$application.Quit()
