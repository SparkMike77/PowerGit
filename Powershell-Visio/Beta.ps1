#This doesn't work, inexplicably generating RPC errors on my local system.


ipmo Visio
$application = New-Object -ComObject Visio.Application 
#$application.visible = $false 
$documents = $application.Documents 
$document = $documents.Add("Basic Network Diagram.vst") 
$pages = $application.ActiveDocument.Pages 
$page = $pages.Item(1) 
 
$NetworkStencil = $application.Documents.Add("periph_m.vss") 
$ComputerStencil = $application.Documents.Add("Computers and Monitors.vss") 
$ConnectorStencil = $application.Documents.Add("Connectors.vss") 
$pc = $ComputerStencil.Masters.Item("PC") 
#$server = $NetworkStencil.Masters.Item("Server")
Open-VisioDocument -Filename "C:\SiteInfo\Visio\Network and Peripherals - 3D.vss"
get-visiomaster -Document $NetworkStencil
#$NetworkStencil = Open-VisioDocument -Filename "C:\SiteInfo\Visio\Network and Peripherals - 3D.vss"
$server = Get-VisioMaster -Document $NetworkStencil -Name "Server"

$X = 3;$Y = 0;

New-VisioShape -Masters $server -Names "Test" -Points $X,$Y;
