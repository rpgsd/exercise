public class NewLeadAppointmentController {

    String dtFormat = 'yyyy-MM-dd\'T\'HH:mm:ssZ';
    
    public Lead lead {get;set;}
    public NewEvent newEvent {get;set;}
    public Integer userTzOffset {get;set;}
    
    public List<CalEvent> events {get;set;}
    
    public String[] getHours() {
        return new String[]
        {'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'};
    }
    
    public String[] getMinutes() {
        return makeNumericStrings(60);
    }
    
    String[] makeNumericStrings(Integer max) {
        String[] sa = new String[max];
        for (Integer i = 0; i < max; i++) {
            sa[i] = '' + i;
        }
        return sa;
    }
    
    public String[] getAmOrPm() {
        return new String[]{'AM','PM'};
    }

    public NewLeadAppointmentController() {
        if (ApexPages.currentPage().getParameters().get('id') != null) {
            newEvent = new NewEvent();
            lead = [SELECT FirstName, LastName, Email, Phone,
                    Street, City, State, PostalCode, Country,
                    Owner.FirstName, Owner.LastName,
                    Owner.Email, Owner.Phone
                    FROM Lead WHERE Id = 
                    :ApexPages.currentPage().getParameters().get('id')];
           TimeZone tz = UserInfo.getTimeZone(); 
           userTzOffset = tz.getOffset(DateTime.now()) / 3600000;
        }
    }

    public PageReference pageLoad() {
        if (lead == null) {
			PageReference pageError = Page.error;
            pageError.getParameters().put('errorCode', '101');
			pageError.setRedirect(true);
			return(pageError);            
        }
        
        events = new List<CalEvent>();
        for(Event event: [select Id, Subject, ShowAs, Who.Name,
                          StartDateTime, EndDateTime from Event
                          where OwnerID = :UserInfo.getUserId()]){
            DateTime startDT = event.StartDateTime;
            DateTime endDT = event.EndDateTime;
            CalEvent myEvent = new CalEvent();
            myEvent.title = event.Subject + ' - ' + event.Who.Name;
            myEvent.showAs = event.ShowAs;
            myEvent.startString = startDT.format(dtFormat);
            myEvent.endString = endDT.format(dtFormat);
            myEvent.url = '/' + event.Id;
            events.add(myEvent);
        }
        return null;
    }
    
    public PageReference save() {
        Id oppId = null;
        Event event = new Event();
        try {
            Database.LeadConvert leadConvert = new Database.LeadConvert();
            leadConvert.setLeadId(lead.id);
			LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus
                                        WHERE IsConverted=true LIMIT 1];
			leadConvert.setConvertedStatus(convertStatus.MasterLabel);
            Database.LeadConvertResult conversionResult = Database.convertLead(leadConvert);

            event.Subject = newEvent.subject;
            event.ShowAs = newEvent.showAs;
            event.StartDateTime =
                DateTime.newInstance(newEvent.eventYear, newEvent.eventMonth, newEvent.eventDay, newEvent.startHour, newEvent.startMinute, 0);
            event.EndDateTime =
                DateTime.newInstance(newEvent.eventYear, newEvent.eventMonth, newEvent.eventDay, newEvent.endHour, newEvent.endMinute, 0);
            event.OwnerId = lead.OwnerId;
            event.WhoId = conversionResult.getContactId();
            oppId = conversionResult.getOpportunityId();
            event.WhatId = oppId;
            insert(event);
            
        } catch(System.DMLException e) {
            ApexPages.addMessages(e);
            return null;
        }
        
        //  After successful save, navigate to event checker
        //  where we validate travel times + 30 minute buffer time
        PageReference pageSucess = new PageReference(Page.EventChecker.getUrl()
        	+ '?id=' + event.Id);
        return (pageSucess);
    }

    public class CalEvent {
        public String title {get;set;}
        public String showAs {get;set;}
        public String startString {get;private set;}
        public String endString {get;private set;}
        public String url {get;set;}
    }

    public class NewEvent {
        public String subject {get;set;}
        public String showAs {get;set;}
        public Integer eventYear {get;set;}
        public Integer eventMonth {get;set;}
        public Integer eventDay {get;set;}
        public Integer startHour {get;set;}
        public Integer startMinute {get;set;}
        public Integer endHour {get;set;}
        public Integer endMinute {get;set;}
    }
}
