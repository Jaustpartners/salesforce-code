# salesforce-code

<b>InvoiceEngine.cls:</b> This Apex class, will auto generate Invoice for a service ticket and is based on complex set of business rules.  The rules will take in to account Enittlements the user has, Product Price Lists, Employee RateLists and will apply on Time, Expense and Part Movements performed on work order and any customer orders associated with the Service Ticket. The code is invoked from a button on Service Ticket.

<b>EntitlementUtilities.cls:</b> This Apex class will allow the administrator to generate new entitlements for the customer, with complicated set of rules, by using pre configured Entitlement Templates as its base.

<b>Dispatch_Board.page:</b> This Visualforce page is written in Jquery and Visualforce. The Dispatcher can use drag and drop functionality to assign the Field Service Tasks to Technicians. The drop downs allow the dispatcher to chooose specific service region and date. The dispatcher drags the Field task from bottom applet and drops at a specific date,time on the dispatch board.

