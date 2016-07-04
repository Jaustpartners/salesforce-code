global with sharing class InvoiceEngine {

    
    webservice static String generateInvoice(string serviceTicketId)
    {
        String returnMsg = 'started generating invoice';
        string accountId = '';
        String entitlementId = '';
        String invoiceId = '';
        Map<String, Entitlement_Service_Coverage__c> m;
        
        //Search SR and get info
         Service_Ticket__c SrvTicket =
             [SELECT Account__c,Entitlement__c,Billable__c,Bill_Override__c
              FROM Service_Ticket__c WHERE Id = :serviceTicketId];
        if(SrvTicket.Billable__c == false || SrvTicket.Bill_Override__c == true)
        {
            returnMsg = 'Invoice not generated as Service Ticket is not Billable or Bill Override is true';
            return returnMsg;
        }
      
        accountId = SrvTicket.Account__c;
        entitlementId = SrvTicket.Entitlement__c;
        //Create Invoice Header
        Invoice__c inv = createInvoiceHeader(accountId, serviceTicketId);
        invoiceId = inv.Id;
        Entitlement__c e = readEntitlement(entitlementId);
        m= getEntitlementCoverageMap(e);
        Service_Ticket__c ST = readServiceTicket(serviceTicketId);
        //Loop through all Service Ticket Tasks
        for(Service_Task__c ST_Task:ST.Service_Tasks__r)
        {
            //For current Service Ticket Task
            
            //read entitlementMap for Key:TaskType
            Entitlement_Service_Coverage__c taskCoverage = m.get(ST_Task.Task_Type__c);
            
            //If Minimum Task Charge is > 0,as defined by Entitlement
            if(taskCoverage.Minimum_Charge__c > 0 && ST_Task.Override_Minimum__c == false)
                {
                    //Create Invoice Line Item for Minimum Task Charge as defined by Entitlement
                    createInvoiceLineItem(invoiceId,'Fee',taskCoverage.Minimum_Charge__c, 
                                        ST_Task.Id, null, null, null);
                }
            
            if(taskCoverage.Time_Billable__c || taskCoverage.Expenses_Billable__c || taskCoverage.Parts_Billable__c)
            {
                Service_Task__c ST_Task_Detail = readServiceTicketTask (ST_Task.Id);
            //If Time is billable as defined by Entitlement
                if(taskCoverage.Time_Billable__c)
                    {
                        //Loop through all Time Capture Records for current Service Ticket task    
                        for(Time_Capture__c STT_timeCapture:ST_Task_Detail.Time_Captures__r)
                        {
                            //Get billing rate of employee on TimeCapture record and RateBook on Service Ticket       
                            //System.debug('Time: ' + STT_timeCapture.Total_Worked_in_Minutes__c);
                            Decimal rate = getEmployeeHourlyRate(STT_timeCapture.Employee__c,e.Ratebook__c);
                            Decimal timeCost = (rate * STT_timeCapture.Total_Worked_in_Minutes__c)/60;
                            //Create Invoice Line Item for each TimeCapture record
                            createInvoiceLineItem(invoiceId,'Time',timeCost , 
                                        ST_Task.Id,STT_timeCapture.Id , null, null);
                            
                        }
 
                    }
    
                
                //If Expense is billable as defined by Entitlement
                if(taskCoverage.Expenses_Billable__c)
                    {
                        //Loop through all Expense Capture Records for current Service Ticket task
                        for(Expense_Capture__c STT_expenseCapture:ST_Task_Detail.Expense_Captures__r)
                        {
                            //System.debug('Expense: ' + STT_expenseCapture.Amount__c);
                            Decimal expense = STT_expenseCapture.Amount__c;
                            //Create Invoice Line Item for each ExpenseCapture record 
                            createInvoiceLineItem(invoiceId,'Expense',expense , 
                                        ST_Task.Id,null , STT_expenseCapture.Id, null);                            
                            
                        }
                        
                                            
                    }            
    
    
                //If Parts are billable as defined by Entitlement
                if(taskCoverage.Parts_Billable__c)
                    {
                        //Loop through all PartMovement Records for current Service Ticket task
                        for (Part_Movement__c STT_partCapture : ST_Task_Detail.Part_Movements__r)
                            {
                                //System.debug('Part: ' + STT_partCapture.Asset__c);
                                //Get price of Product based on priceList of Service Ticket and Product Code
                                Decimal productPrice = getProductPrice(STT_partCapture.Products__c, e.PriceBook__c);
                                //Create Invoice Line Item for each PartMovement record
                                createInvoiceLineItem(invoiceId,'Part Movement',productPrice , 
                                        ST_Task.Id,null , null, STT_partCapture.Id);
                                
                            }
                                             
                    }                           
                
            }


            
        }
        
        
        
        return returnMsg;
    }
    
    private static Service_Ticket__c readServiceTicket (String serviceTicketId)
    {
        Service_Ticket__c ST = [SELECT Id, Name,Account__c,Entitlement__c,Billable__c,Bill_Override__c, 
                                (SELECT Id, Name,Task_Type__c,Override_Minimum__c FROM Service_Tasks__r)
             FROM Service_Ticket__c
             WHERE Id= :serviceTicketId]; 
        return ST;
    }

    private static Service_Task__c readServiceTicketTask (String serviceTicketTaskId)
    {
        Service_Task__c STT = [SELECT Id, Name,Task_Type__c,Override_Minimum__c, 
                                (SELECT Id, Name,Override_Time__c,Total_Worked_in_Minutes__c,Employee__c 
                                 FROM Time_Captures__r
                                WHERE Override_Time__c = false AND Total_Worked_in_Minutes__c > 0),
                               (SELECT Id, Name,Override_Expense__c,Amount__c,Employee__c 
                                 FROM Expense_Captures__r
                                WHERE Override_Expense__c = false AND Amount__c > 0),
                               (SELECT Id, Name,Override_Part__c,Products__c,Quantity__c,Asset__c 
                                 FROM Part_Movements__r
                                WHERE Override_Part__c = false AND Destination__c = 'Customer' AND Commit_Part_Movement__c = true)
             FROM Service_Task__c
             WHERE Id= :serviceTicketTaskId];

        return STT;
    }    
    
    private static Entitlement__c readEntitlement (String entitlementId)
    {
        Entitlement__c e = 
            [SELECT Id, Name,Type__c,Status__c,PriceBook__c,Ratebook__c,Charge__c, 
                           (SELECT Id, Name,Service_Task_Type__c,Time_Billable__c,Expenses_Billable__c,
                            Parts_Billable__c,Minimum_Charge__c 
                            FROM Entitlement_Services_Coverage__r)
             FROM Entitlement__c
             WHERE Id= :entitlementId];

        return e;
    } 
    
    private static Invoice__c createInvoiceHeader(string accountId, string serviceTicketId)
    {
        //Create invoice record
        Invoice__c inv = new Invoice__c(Invoice_State__c='Open',Service_Ticket__c=serviceTicketId,Account__c=accountId);

        //Save record
        insert inv;
        return inv;
        
    }
     private static void createInvoiceLineItem(String invoiceHeaderId, String lineItemType, Decimal amount, 
                                        Id taskRecId, Id timeRecId, Id expenseRecId, Id partMvmntId)
    {
        Invoice_Line_Item__c invLineItem = new Invoice_Line_Item__c
            (Invoice__c=invoiceHeaderId,Line_Item_Type__c=lineItemType,Amount__c=amount,
            Service_Ticket_Task__c = taskRecId, Time_Capture_Rec__c = timeRecId, 
             Expense_Capture_Rec__c = expenseRecId, Part_Movement_Rec__c = partMvmntId);

        //Populate fields
        //Associate to Invoice
        //Save record
        insert invLineItem;
        
    }
    
    public static double getEmployeeHourlyRate(Id employeeId, Id ratebookId)
    {
        double rate = 0;
        //Search for employee record, Get employee resource code
        User employee = 
            [SELECT Id,Username,Resource_Rate_Code__c,User_Type__c
                            FROM User
             WHERE Id= :employeeId];
        string userResourceCode = employee.Resource_Rate_Code__c;

        //Search for Rate record(and childs), Get Child record based on employee resource code, Get the rate
        Rate_Book__c rateBook = 
            [SELECT Id, Name, 
                           (SELECT Id, Name,Resource_Rate_Code__c,Standard_Price__c 
                            FROM Rate_Book_Items__r
                            where Resource_Rate_Code__c = :userResourceCode )
             FROM Rate_Book__c
             WHERE Id= :ratebookId];
        Rate_Book_Item__c rateBookItem = rateBook.Rate_Book_Items__r[0];
        rate = rateBookItem.Standard_Price__c;

        return rate;
    }
    
    private static double getProductPrice(Id productId, Id pricebookid)
    {
        double productPrice = 500;
        return productPrice;
    }
    private static Map<String, Entitlement_Service_Coverage__c> getEntitlementCoverageMap(Entitlement__c e)
    {
        Map<String, Entitlement_Service_Coverage__c> m = new Map<String, Entitlement_Service_Coverage__c>();
        //Entitlement__c e = readEntitlement(entitlementId);
        for (Entitlement_Service_Coverage__c coverage : e.Entitlement_Services_Coverage__r)
            {
                //System.debug('Type: ' + coverage.Service_Task_Type__c);
                string key = coverage.Service_Task_Type__c;
                m.put(key,coverage);        
            }
        return m;     
    }
    
}