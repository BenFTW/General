#This is a collection of scripts to work with IPv4 addresses
#Dot Source this file.
#NOT WRITTEN BY ME. DOWNLOADED FROM http://www.indented.co.uk/2010/01/23/powershell-subnet-math/

# Use of Convert Functions
#ConvertTo-BinaryIP 192.168.1.1
#ConvertTo-DecimalIP 192.168.1.1
#ConvertTo-DottedDecimalIP 11000000.10101000.00000001.00000001
#ConvertTo-DottedDecimalIP 3232235777
#ConvertTo-MaskLength 255.255.128.0
#ConvertTo-Mask 17
 
# Use of Network and Broadcast Address Functions
#Get-NetworkAddress 192.168.1.1 255.255.255.0
#Get-BroadcastAddress 192.168.1.1 255.255.255.0
 
# Use of Network Info
#Get-NetworkSummary 229.168.1.1 255.255.248.0
#Get-NetworkSummary 172.16.1.243 18
#Get-NetworkSummary 10.0.0.3/14
 
# Use of Network Range
#Get-NetworkRange 192.168.1.5 255.255.255.248
#Get-NetworkRange 172.18.0.23 30
#Get-NetworkRange 172.18.0.23/29

Function ConvertTo-BinaryIP {
  <#
    .Synopsis
      Converts a Decimal IP address into a binary format.
    .Description
      ConvertTo-BinaryIP uses System.Convert to switch between decimal and binary format. The output from this function is dotted binary.
    .Parameter IPAddress
      An IP Address to convert.
  #>
 
  [CmdLetBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
    [Net.IPAddress]$IPAddress
  )
 
  Process {  
    Return [String]::Join('.', $( $IPAddress.GetAddressBytes() |
      ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') } ))
  }
}
Function ConvertTo-DecimalIP {
  <#
    .Synopsis
      Converts a Decimal IP address into a 32-bit unsigned integer.
    .Description
      ConvertTo-DecimalIP takes a decimal IP, uses a shift-like operation on each octet and returns a single UInt32 value.
    .Parameter IPAddress
      An IP Address to convert.
  #>
   
  [CmdLetBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
    [Net.IPAddress]$IPAddress
  )
 
  Process {
    $i = 3; $DecimalIP = 0;
    $IPAddress.GetAddressBytes() | ForEach-Object { $DecimalIP += $_ * [Math]::Pow(256, $i); $i-- }
 
    Return [UInt32]$DecimalIP
  }
}
Function ConvertTo-DottedDecimalIP {
  <#
    .Synopsis
      Returns a dotted decimal IP address from either an unsigned 32-bit integer or a dotted binary string.
    .Description
      ConvertTo-DottedDecimalIP uses a regular expression match on the input string to convert to an IP address.
    .Parameter IPAddress
      A string representation of an IP address from either UInt32 or dotted binary.
  #>
 
  [CmdLetBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
    [String]$IPAddress
  )
   
  Process {
    Switch -RegEx ($IPAddress) {
      "([01]{8}\.){3}[01]{8}" {
        Return [String]::Join('.', $( $IPAddress.Split('.') | ForEach-Object { [Convert]::ToUInt32($_, 2) } ))
      }
      "\d" {
        $IPAddress = [UInt32]$IPAddress
        $DottedIP = $( For ($i = 3; $i -gt -1; $i--) {
          $Remainder = $IPAddress % [Math]::Pow(256, $i)
          ($IPAddress - $Remainder) / [Math]::Pow(256, $i)
          $IPAddress = $Remainder
         } )
        
        Return [String]::Join('.', $DottedIP)
      }
      default {
        Write-Error "Cannot convert this format"
      }
    }
  }
}
Function ConvertTo-MaskLength {
  <#
    .Synopsis
      Returns the length of a subnet mask.
    .Description
      ConvertTo-MaskLength accepts any IPv4 address as input, however the output value 
      only makes sense when using a subnet mask.
    .Parameter SubnetMask
      A subnet mask to convert into length
  #>
 
  [CmdLetBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
    [Alias("Mask")]
    [Net.IPAddress]$SubnetMask
  )
 
  Process {
    $Bits = "$( $SubnetMask.GetAddressBytes() | ForEach-Object { [Convert]::ToString($_, 2) } )" -Replace '[\s0]'
 
    Return $Bits.Length
  }
}
Function ConvertTo-Mask {
  <#
    .Synopsis
      Returns a dotted decimal subnet mask from a mask length.
    .Description
      ConvertTo-Mask returns a subnet mask in dotted decimal format from an integer value ranging 
      between 0 and 32. ConvertTo-Mask first creates a binary string from the length, converts 
      that to an unsigned 32-bit integer then calls ConvertTo-DottedDecimalIP to complete the operation.
    .Parameter MaskLength
      The number of bits which must be masked.
  #>
   
  [CmdLetBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
    [Alias("Length")]
    [ValidateRange(0, 32)]
    $MaskLength
  )
   
  Process {
    Return ConvertTo-DottedDecimalIP ([Convert]::ToUInt32($(("1" * $MaskLength).PadRight(32, "0")), 2))
  }
}
Function Get-NetworkAddress {
  <#
    .Synopsis
      Takes an IP address and subnet mask then calculates the network address for the range.
    .Description
      Get-NetworkAddress returns the network address for a subnet by performing a bitwise AND 
      operation against the decimal forms of the IP address and subnet mask. Get-NetworkAddress
      expects both the IP address and subnet mask in dotted decimal format.
    .Parameter IPAddress
      Any IP address within the network range.
    .Parameter SubnetMask
      The subnet mask for the network.
  #>
   
  [CmdLetBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
    [Net.IPAddress]$IPAddress,
     
    [Parameter(Mandatory = $True, Position = 1)]
    [Alias("Mask")]
    [Net.IPAddress]$SubnetMask
  )
 
  Process {
    Return ConvertTo-DottedDecimalIP ((ConvertTo-DecimalIP $IPAddress) -BAnd (ConvertTo-DecimalIP $SubnetMask))
  }
}
Function Get-BroadcastAddress {
  <#
    .Synopsis
      Takes an IP address and subnet mask then calculates the broadcast address for the range.
    .Description
      Get-BroadcastAddress returns the broadcast address for a subnet by performing a bitwise AND 
      operation against the decimal forms of the IP address and inverted subnet mask. 
      Get-BroadcastAddress expects both the IP address and subnet mask in dotted decimal format.
    .Parameter IPAddress
      Any IP address within the network range.
    .Parameter SubnetMask
      The subnet mask for the network.
  #>
   
  [CmdLetBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
    [Net.IPAddress]$IPAddress, 
     
    [Parameter(Mandatory = $True, Position = 1)]
    [Alias("Mask")]
    [Net.IPAddress]$SubnetMask
  )
 
  Process {
    Return ConvertTo-DottedDecimalIP $((ConvertTo-DecimalIP $IPAddress) -BOr `
      ((-BNot (ConvertTo-DecimalIP $SubnetMask)) -BAnd [UInt32]::MaxValue))
  }
}
Function Get-NetworkSummary ( [String]$IP, [String]$Mask ) {
  If ($IP.Contains("/"))
  {
    $Temp = $IP.Split("/")
    $IP = $Temp[0]
    $Mask = $Temp[1]
  }
 
  If (!$Mask.Contains("."))
  {
    $Mask = ConvertTo-Mask $Mask
  }
 
  $DecimalIP = ConvertTo-DecimalIP $IP
  $DecimalMask = ConvertTo-DecimalIP $Mask
   
  $Network = $DecimalIP -BAnd $DecimalMask
  $Broadcast = $DecimalIP -BOr
    ((-BNot $DecimalMask) -BAnd [UInt32]::MaxValue)
  $NetworkAddress = ConvertTo-DottedDecimalIP $Network
  $RangeStart = ConvertTo-DottedDecimalIP ($Network + 1)
  $RangeEnd = ConvertTo-DottedDecimalIP ($Broadcast - 1)
  $BroadcastAddress = ConvertTo-DottedDecimalIP $Broadcast
  $MaskLength = ConvertTo-MaskLength $Mask
   
  $BinaryIP = ConvertTo-BinaryIP $IP; $Private = $False
  Switch -RegEx ($BinaryIP)
  {
    "^1111"  { $Class = "E"; $SubnetBitMap = "1111" }
    "^1110"  { $Class = "D"; $SubnetBitMap = "1110" }
    "^110"   { 
      $Class = "C"
      If ($BinaryIP -Match "^11000000.10101000") { $Private = $True } }
    "^10"    { 
      $Class = "B"
      If ($BinaryIP -Match "^10101100.0001") { $Private = $True } }
    "^0"     { 
      $Class = "A"
      If ($BinaryIP -Match "^00001010") { $Private = $True } }
   }   
    
  $NetInfo = New-Object Object
  Add-Member NoteProperty "Network" -Input $NetInfo -Value $NetworkAddress
  Add-Member NoteProperty "Broadcast" -Input $NetInfo -Value $BroadcastAddress
  Add-Member NoteProperty "Range" -Input $NetInfo `
    -Value "$RangeStart - $RangeEnd"
  Add-Member NoteProperty "Mask" -Input $NetInfo -Value $Mask
  Add-Member NoteProperty "MaskLength" -Input $NetInfo -Value $MaskLength
  Add-Member NoteProperty "Hosts" -Input $NetInfo `
    -Value $($Broadcast - $Network - 1)
  Add-Member NoteProperty "Class" -Input $NetInfo -Value $Class
  Add-Member NoteProperty "IsPrivate" -Input $NetInfo -Value $Private
   
  Return $NetInfo
}

Function Get-NetworkRange( [String]$IP, [String]$Mask ) {
  If ($IP.Contains("/"))
  {
    $Temp = $IP.Split("/")
    $IP = $Temp[0]
    $Mask = $Temp[1]
  }
 
  If (!$Mask.Contains("."))
  {
    $Mask = ConvertTo-Mask $Mask
  }
 
  $DecimalIP = ConvertTo-DecimalIP $IP
  $DecimalMask = ConvertTo-DecimalIP $Mask
   
  $Network = $DecimalIP -BAnd $DecimalMask
  $Broadcast = $DecimalIP -BOr ((-BNot $DecimalMask) -BAnd [UInt32]::MaxValue)
 
  For ($i = $($Network + 1); $i -lt $Broadcast; $i++) {
    ConvertTo-DottedDecimalIP $i
  }
}
