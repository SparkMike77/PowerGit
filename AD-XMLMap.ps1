Function ConvertTo-CustomXML {
    Param(
        [Parameter(
            Mandatory = $True,
            ValueFromPipeline = $True
        )]
        [Object[]]
        $InputObject,

        [XML]
        $XMLDocument
    )

    Begin {
        If(-not $XMLDocument) {
            $XMLDocument = [xml]"<objects></objects>"
        }
    }

    Process {
        ForEach($object in $InputObject) {
            $properties = $object | Get-Member -MemberType Property | Select-Object -ExpandProperty Name
            If($object.ObjectClass) {$element = $XMLDocument.DocumentElement.AppendChild($XMLDocument.CreateElement( $object.ObjectClass ))} 
            Else {$element = $XMLDocument.DocumentElement.AppendChild( "object" )}

            ForEach($property in $properties) {
                $subelement = $XMLDocument.CreateElement($property)
                $text = $XMLDocument.CreateTextNode($object."$property")
                $subelement.AppendChild($text) | Out-Null
                $element.AppendChild($subelement) | Out-Null
            }
        }
    }

    End {
        Return $XMLDocument
    }
}
$props = 'DistinguishedName','DisplayName','Manager','EmailAddress'

(get-AdUser -filter * -SearchBase "DC=durabuilt,DC=net" -Property $props |
 select $props | ConvertTo-CustomXML -NoTypeInformation ).Save("C:\temp\ADINFORMATION.xml")