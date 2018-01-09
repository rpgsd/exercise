public class EventChecker {

    private final Integer BUFFER_TIME = 1800; // 30 minutes;
    private final String DATE_FORMAT = 'yyyy-MM-dd HH:mm z';
    
    Event event;
    String validationMessage;
    Contact contact {get;set;}
    
    public Event getEvent() {
        return event;
    }
    
    public String getValidationMessage() {
        return validationMessage;
    }
    
    public EventChecker() {
        if (ApexPages.currentPage().getParameters().get('id') != null) {
            event = [SELECT Id, StartDateTime, EndDateTime, WhatId,
                    TYPEOF WHO
                        // next 'WHEN' line compiles but I can't access the fields at run-time,
                        // I had to create a separate Contact object and look-up :( (serializing the object could be an option, too)
                     	// WHEN contact then MailingStreet, MailingCity, MailingState, MailingPostalCode
                        WHEN contact then Id
                    END
                    FROM Event WHERE Id = 
                    :ApexPages.currentPage().getParameters().get('id')];
            contact = [select MailingStreet, MailingCity,
                       MailingState, MailingPostalCode from Contact
                      where Id = :event.WhoId];
        }
    }

    public PageReference pageLoad() {
        if (event == null) {
			PageReference pageError = Page.error;
            pageError.getParameters().put('errorCode', '102');
			pageError.setRedirect(true);
			return(pageError);            
        }
        
        Contact c = null;
        String stringMessage = null;
        ApexPages.Message apexMessage = null;
        Integer travelTime = 0;
        Integer travelWithBufferTime = 0;
        DateTime prevDateTime = null;
        validationMessage = '';

      	// check an earlier event to the new event
        Event[] earlierEvents = [select Id, StartDateTime, EndDateTime,
                          TYPEOF WHO
                              WHEN contact THEN Id
                          END
                          FROM Event
                          WHERE OwnerID = :UserInfo.getUserId()
                          AND StartDateTime < :event.StartDateTime
                          ORDER BY StartDateTime];
        if (earlierEvents.size() > 0) {
            Event earlierEvent = earlierEvents[0];
            c = [select MailingStreet, MailingCity,
                      MailingState, MailingPostalCode from Contact
                      where Id = :earlierEvent.WhoId];
            travelTime = getTravelTime(
            	c.mailingStreet, c.mailingCity, c.mailingState,
                contact.mailingStreet, contact.mailingCity, contact.mailingState);
            prevDateTime = earlierEvent.EndDateTime;
            travelWithBufferTime = travelTime + BUFFER_TIME;
            prevDateTime = prevDateTime.addSeconds(travelWithBufferTime);
            if (prevDateTime > event.StartDateTime) {
            	stringMessage = makeWarningMessage(
                    earlierEvent.EndDateTime.format(DATE_FORMAT),
                    event.StartDateTime.format(DATE_FORMAT), travelWithBufferTime / 60,
                	c.mailingStreet, c.mailingCity, c.mailingState,
                    contact.mailingStreet, contact.mailingCity, contact.mailingState);
                validationMessage += stringMessage;
                apexMessage = new ApexPages.Message(ApexPages.SEVERITY.WARNING, stringMessage);
            	ApexPages.addMessage(apexMessage);
            }
        }
        
      	// check a later event to the new event
        Event[] laterEvents = [select Id, StartDateTime, EndDateTime,
                          TYPEOF WHO
                              WHEN contact THEN Id
                          END
                          FROM Event
                          WHERE OwnerID = :UserInfo.getUserId()
                          AND StartDateTime > :event.StartDateTime
                          ORDER BY StartDateTime];
        if (laterEvents.size() > 0) {
            Event laterEvent = laterEvents[0];
            c = [select MailingStreet, MailingCity,
                      MailingState, MailingPostalCode from Contact
                      where Id = :laterEvent.WhoId];
            travelTime = getTravelTime(
            	contact.mailingStreet, contact.mailingCity, contact.mailingState,
                c.mailingStreet, c.mailingCity, c.mailingState);
            prevDateTime = event.EndDateTime;
            travelWithBufferTime = travelTime + BUFFER_TIME;
            prevDateTime = prevDateTime.addSeconds(travelWithBufferTime);
            if (prevDateTime > laterEvent.StartDateTime) {
            	stringMessage = makeWarningMessage(
                    event.EndDateTime.format(DATE_FORMAT),
                    laterEvent.StartDateTime.format(DATE_FORMAT), travelWithBufferTime / 60,
                    contact.mailingStreet, contact.mailingCity, contact.mailingState,
                	c.mailingStreet, c.mailingCity, c.mailingState);
                validationMessage += stringMessage;
                apexMessage = new ApexPages.Message(ApexPages.SEVERITY.WARNING, stringMessage);
            	ApexPages.addMessage(apexMessage);
            }
        }
        
        if (stringMessage == null) {
            stringMessage = 'We checked your travel time between appointments. Looks good!';
            validationMessage = stringMessage;
            apexMessage = new ApexPages.Message(ApexPages.SEVERITY.INFO, stringMessage);
            ApexPages.addMessage(apexMessage);
        }
        
        return null;
        
    }
    
    public Integer getTravelTime(
        	String prevStreet, String prevCity, String prevState,
            String nextStreet, String nextCity, String nextState) {
     	String origin = 'origins=' + prevStreet + '+' + prevCity + '+' + prevState;
        origin = origin.replaceAll(' ', '+');
     	String destination = 'destinations=' + nextStreet + '+' + nextCity + '+' + nextState;
        destination = destination.replaceAll(' ', '+');
        
        HttpRequest req = new HttpRequest();
     	String requestUrl = 'https://maps.googleapis.com/maps/api/distancematrix/json?key=AIzaSyBJTWHFy19Ow4QaMw2EITLU0miaqHW_i_M';
        requestUrl += '&' + origin;
        requestUrl += '&' + destination;
        req.setEndpoint(requestUrl);
     	req.setMethod('GET');
     	Http http = new Http();
     	HTTPResponse res = http.send(req);
        JSONParser parser = JSON.createParser(res.getBody());
        Integer travelTime = 0;
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)
                	&& (parser.getText() == 'duration')) {
                while (parser.nextToken() != null) {
            		if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)
                			&& (parser.getText() == 'value')) {
            			parser.nextToken();
                    	travelTime = parser.getIntegerValue();
                        break;
                	}
                }
                break;
            }
        }
                
        return traveltime;
    }
    
    public String makeWarningMessage(String stopDateTime, String startDateTime, Integer travelMinutes,
        	String prevStreet, String prevCity, String prevState,
    		String nextStreet, String nextCity, String nextState) {
        String message = '';
        String origin = prevStreet + ', ' + prevCity + ', ' + prevState;
        String destination = nextStreet + ', ' + nextCity + ', ' + nextState;
        message += 'Based on your appointment at ' + origin + ', ending at ' + stopDateTime;
        message += ', and your next appointment is at ' + origin + ', starting at ' + startDateTime;
        message += ', and with an estimated travel time of ' + travelMinutes + ' minutes between the two locations';
        message += ', you will have less than 30 minutes of preparation or buffer time between the two meetings.\n\n';
        return message;
    }
}
