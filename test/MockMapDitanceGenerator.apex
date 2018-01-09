@isTest
global class MockMapDitanceGenerator implements HttpCalloutMock {

    String requestUrl = 'https://maps.googleapis.com/maps/api/distancematrix/json?key=';
    
    global HTTPResponse respond(HTTPRequest req) {
        System.assert(req.getEndpoint().startsWith(requestUrl));
        System.assertEquals('GET', req.getMethod());
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        // mock an hour of drive time
        res.setBody('{"duration":{"text":"60 minutes","value":3600}}');
        res.setStatusCode(200);
        return res;
    }

}
