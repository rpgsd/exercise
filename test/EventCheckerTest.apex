@isTest
public class EventCheckerTest {

    @isTest
    public static void testRedirectToErrorPage() {
        PageReference pageRef = Page.error;
        Test.setCurrentPage(pageRef);
        EventChecker controller = new EventChecker();
        String nextPage = controller.pageLoad().getUrl();
        System.assertEquals('/apex/error?errorCode=102', nextPage);
    }

    @isTest
    public static void testNoTravelWarning() {
        DateTime now = DateTime.now();
        DateTime dt1 = now.addDays(1);
        DateTime dt2 = dt1.addHours(1);
        Contact newContact = createContact(
            'newFirstName111', 'newLastName111', '123 Main St', 'Austin', 'Tx');
        Event newEvent = createEvent(dt1, dt2, newContact.Id);
        
        // set a previous event with a 2.5 hours star prior to new event
        // set the duration of this appointment for an hour
        // the mock returns a travel time of an hour, add the 30 minute buffer
        // we should not get a travel warning then
        DateTime dt3 = dt1.addMinutes(-150);
        DateTime dt4 = dt3.addMinutes(60);
        Contact prevContact1 = createContact(
            'oldFirstName111', 'oldLastName111', '456 Main St', 'Austin', 'Tx');
        Event oldEvent1 = createEvent(dt3, dt4, prevContact1.Id);
        
        // set a next event with a 1.5 hours star after the new event
        // (the duration, or end time, of this meeting doesn't really matter)
        // we should not get a travel warning then
        DateTime dt5 = dt2.addMinutes(150);
        DateTime dt6 = dt5.addMinutes(60);
        Contact prevContact2 = createContact(
            'oldFirstName222', 'oldLastName222', '789 Main St', 'Austin', 'Tx');
        Event oldEvent2 = createEvent(dt5, dt6, prevContact2.Id);

        Test.startTest();
        PageReference pageRef = Page.EventChecker;
        ApexPages.currentPage().getParameters().put('id', newEvent.Id);
        Test.setMock(HttpCalloutMock.class, new MockMapDitanceGenerator());
        EventChecker controller = new EventChecker();
        controller.pageLoad();
		List<Apexpages.Message> msgs = ApexPages.getMessages();
        System.assert(msgs.size() == 1);
        System.assert(msgs[0].getSeverity() == ApexPages.SEVERITY.INFO);
    }
    
    @isTest
    public static void testGetTravelWarnings() {
        DateTime now = DateTime.now();
        DateTime dt1 = now.addDays(1);
        DateTime dt2 = dt1.addHours(1);
        Contact newContact = createContact(
            'newFirstName111', 'newLastName111', '123 Main St', 'Austin', 'Tx');
        Event newEvent = createEvent(dt1, dt2, newContact.Id);
        
        // set a previous event with a 2 hours and 29 minutes star prior to new event
        // set the duration of this appointment for an hour
        // the mock returns a travel time of an hour, add the 30 minute buffer
        // we should get a warning since we over target travel + buffer time 
        DateTime dt3 = dt1.addMinutes(-149);
        DateTime dt4 = dt3.addMinutes(60);
        Contact prevContact1 = createContact(
            'oldFirstName111', 'oldLastName111', '456 Main St', 'Austin', 'Tx');
        Event oldEvent1 = createEvent(dt3, dt4, prevContact1.Id);
        
        // set a next event with a 89 minutes star after the new event
        // (the duration, or end time, of this meeting doesn't really matter)
        // we should get a warning since we over target travel + buffer time 
        DateTime dt5 = dt2.addMinutes(89);
        DateTime dt6 = dt5.addMinutes(60);
        Contact prevContact2 = createContact(
            'oldFirstName222', 'oldLastName222', '789 Main St', 'Austin', 'Tx');
        Event oldEvent2 = createEvent(dt5, dt6, prevContact2.Id);

        Test.startTest();
        PageReference pageRef = Page.EventChecker;
        ApexPages.currentPage().getParameters().put('id', newEvent.Id);
        Test.setMock(HttpCalloutMock.class, new MockMapDitanceGenerator());
        EventChecker controller = new EventChecker();
        controller.pageLoad();
		List<Apexpages.Message> msgs = ApexPages.getMessages();
        System.assert(msgs.size() == 2);
        System.assert(msgs[0].getSeverity() == ApexPages.SEVERITY.WARNING);
        System.assert(msgs[1].getSeverity() == ApexPages.SEVERITY.WARNING);
    }
    
    static Contact createContact(String firstName, String lastName,
        	String street, String city, String state) {
        Contact contact = new Contact(
            FirstName = firstName,
        	LastName = lastName,
        	MailingStreet = street,
        	MailingCity = city,
        	MailingState = state);
        insert contact;
        return contact;
    }

    static Event createEvent(DateTime startDateTime, DateTime endDateTime, Id whoId) {
        Event event = new Event(
            Subject = 'Meeting',
        	ShowAs = 'Busy',
            startDateTime = startDateTime,
            endDateTime = endDateTime,
            OwnerId = UserInfo.getUserId(),
        	WhoId = whoId);
        insert event;
        return event;
    }
}
