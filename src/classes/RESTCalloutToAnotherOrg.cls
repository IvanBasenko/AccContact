/**
 * Created by Basenko on 03.10.2018.
 */

public with sharing class RESTCalloutToAnotherOrg implements Queueable, Database.AllowsCallouts {
    private String publicLink;
    private String clientId;
    private String clientSecret;
    private Id customSettingId;
    private String refreshToken;
    private String accessToken;
    private static final String ordDefaultKey = '00D';

    public RESTCalloutToAnotherOrg(String publicLink) {
        this.publicLink = publicLink;
        this.clientId = RefreshToken__c.getOrgDefaults().ClientId__c;
        this.clientSecret = RefreshToken__c.getOrgDefaults().ClientSecret__c;
        this.refreshToken = RefreshToken__c.getOrgDefaults().Token__c;
    }

    public void execute(QueueableContext context) {
        this.accessToken = getAccessToken();
        if (customSettingOrgDefaultIsExist()) {
            pushNewDownloadURL();
        } else {
            createNewOrgDefaultCustomSetting();
        }
    }

    private void createNewOrgDefaultCustomSetting() {
        Id orgId = getOrgId();
        String url = 'https://resourceful-fox-r4h30w-dev-ed.my.salesforce.com/services/data/v43.0/sobjects/AccountDownloadLink__c/';
        String body = '{"DownloadLink__c":"' + publicLink + '","SetupOwnerId":"' + orgId + '"}';
        makeHttpCallout(url, 'POST', body);
    }

    private Id getOrgId() {
        String url = 'https://resourceful-fox-r4h30w-dev-ed.my.salesforce.com/services/data/v43.0/query/?q=SELECT+ID+FROM+Organization';
        HttpResponse response = makeHttpCallout(url, 'GET', null);
        if (response.getStatusCode() == 200) {
            Map<String, Object> result = getDeserializeMap(response.getBody());
            List<Map<String, Object>> records = new List<Map<String, Object>>();
            for (Object o : (List<Object>) result.get('records')) {
                records.add((Map<String, Object>) o);
            }
            return (Id) records.get(0).get('Id');
        }
        return null;
    }
    private void pushNewDownloadURL() {
        String url = 'https://resourceful-fox-r4h30w-dev-ed.my.salesforce.com/services/data/v43.0/sobjects/AccountDownloadLink__c/' + customSettingId;
        String body = '{"DownloadLink__c":"' + publicLink + '"}';
        makeHttpCallout(url, 'PATCH', body);
    }

    private Boolean customSettingOrgDefaultIsExist() {
        String url = 'https://resourceful-fox-r4h30w-dev-ed.my.salesforce.com/services/data/v43.0/query/?q=SELECT+DownloadLink__c,SetupOwnerId,ID+FROM+AccountDownloadLink__c';
        HttpResponse response = makeHttpCallout(url, 'GET', null);
        if (response.getStatusCode() == 200) {
            Map<String, Object> result = getDeserializeMap(response.getBody());
            List<Map<String, Object>> records = new List<Map<String, Object>>();
            for (Object o : (List<Object>) result.get('records')) {
                records.add((Map<String, Object>) o);
            }
            for (Map<String, Object> record : records) {
                Id setupOwnerId = (Id) record.get('SetupOwnerId');
                if (setupOwnerId.getSobjectType().getDescribe().getKeyPrefix().equals(ordDefaultKey)) {
                    customSettingId = (Id) record.get('Id');
                    return true;
                }
            }
        }
        return false;
    }

    private Map<String, Object> getDeserializeMap(String responseBody) {
        return (Map<String, Object>) JSON.deserializeUntyped(responseBody);
    }

    private HttpResponse makeHttpCallout(String url, String method, String body) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        if (method == 'PATCH') {
            request.setMethod('POST');
            url += '?_HttpMethod=PATCH';
        } else {
            request.setMethod(method);
        }

        request.setEndpoint(url);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + accessToken);

        if (String.isNotBlank(body)) {
            request.setBody(body);
        }
        return http.send(request);
    }
    private String getAccessToken() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://login.salesforce.com/services/oauth2/token?grant_type=refresh_token&client_id='
                + clientId + '&client_secret=' + clientSecret + '&refresh_token=' + refreshToken);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            System.debug('response ' + response.getBody());
            Map<String, Object> m = getDeserializeMap(response.getBody());
            return (String) m.get('access_token');
        } else return null;
    }
}
