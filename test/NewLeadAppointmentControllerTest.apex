@isTest
public class NewLeadAppointmentControllerTest {

    static String testCompanyName = 'Acme123';
    static String testPersonLastName = 'Last123';
    
    @isTest
    public static void testRedirectToErrorPage() {
        PageReference pageRef = Page.error;
        Test.setCurrentPage(pageRef);
        NewLeadAppointmentController controller = new NewLeadAppointmentController();
        String nextPage = controller.pageLoad().getUrl();
        System.assertEquals('/apex/error?errorCode=101', nextPage);
    }
    
    @isTest
    public static void testControllerData() {
        NewLeadAppointmentController controller = new NewLeadAppointmentController(); 
		String[] validHours = controller.getHours();
		System.assert(validHours[0] == '1');        
		System.assert(validHours[validHours.size() - 1] == '12');        
		System.assert(validHours.size() == 12); 
        String[] validMinutes = controller.getMinutes();
		System.assert(validMinutes[0] == '0');        
		System.assert(validMinutes[validMinutes.size() - 1] == '59');        
		System.assert(validMinutes.size() == 60); 
        String[] validAmorPm = controller.getAmOrPm();
		System.assert(validAmorPm[0] == 'AM');        
		System.assert(validAmorPm[1] == 'PM');        
		System.assert(validAmorPm.size() == 2); 
    }
    
    @isTest
    public static void testSuccess() {
        // setup test date
        Lead lead = createLead();
        Event savedEvent = createSavedEvent(lead);
        PageReference pageRef = Page.NewLeadAppointment;
        ApexPages.currentPage().getParameters().put('id', lead.Id);
      
        NewLeadAppointmentController controller = new NewLeadAppointmentController(); 
        controller.newEvent = createNewEvent();
        controller.pageLoad();
        String nextPage = controller.save().getUrl();
        System.assert(nextPage.startsWith('/apex/eventchecker?id='));
        
        // An account, opportunity and contact should have been created
        Account account = [SELECT Id FROM Account
                          WHERE name = :testCompanyName];
        System.assert(account != null);
        Opportunity opportunity = [SELECT Id FROM Opportunity
                          WHERE name = :testCompanyName];
        System.assert(opportunity != null);
        Contact contact = [SELECT id from Contact
                          WHERE accountId = :account.Id];
        System.assert(contact != null);

    }

    static Lead createLead() {
        Lead lead = new Lead(
            LastName='LastName123',
            Company='Acme123');
        insert lead;
        return lead;
    }
    
    static Event createSavedEvent(Lead lead) {
        DateTime startDateTime = DateTime.now().addDays(1);
        DateTime endDateTime = startDateTime.addMinutes(60);
        Event event = new Event(
            Subject = 'Meeting',
        	ShowAs = 'Busy',
            startDateTime = startDateTime,
            endDateTime = endDateTime,
            OwnerId = UserInfo.getUserId(),
        	WhoId = lead.Id);
        insert event;
        return event;
    }
    
    static NewLeadAppointmentController.NewEvent createNewEvent() {
		DateTime twoDayFromNow = DateTime.now().addDays(2);
        NewLeadAppointmentController.NewEvent newEvent = new NewLeadAppointmentController.NewEvent();
		newEvent.subject = 'Meeting';
        newEvent.showAs = 'Busy';
		newEvent.eventYear = twoDayFromNow.year();
        newEvent.eventMonth = twoDayFromNow.month();
        newEvent.eventDay = twoDayFromNow.day();
        newEvent.startHour = twoDayFromNow.hour();
        newEvent.startMinute = 0;
        newEvent.endHour = twoDayFromNow.hour() + 1;
        newEvent.endMinute = 0;
		return newEvent;        
    }
}
