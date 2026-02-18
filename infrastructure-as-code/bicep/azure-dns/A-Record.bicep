param zoneName string = 'thinkalike.io'
param prodRecordName string = 'app'
param previewRecordName string = 'app.preview'


resource zone 'Microsoft.Network/dnsZones@2023-07-01-preview' existing = {
  name: zoneName
}

resource record 'Microsoft.Network/dnsZones/A@2023-07-01-preview' = {
  parent: zone
  name: prodRecordName
  properties: {
    TTL: 3600
    CNAMERecord: {
      cname: 'string'
    }
  }
}

resource record2 'Microsoft.Network/dnsZones/A@2023-07-01-preview' = {
  parent: zone
  name: previewRecordName
  properties: {
    TTL: 3600
    CNAMERecord: {
      cname: 'string'
    }
  }
}

output nameServers array = zone.properties.nameServers
