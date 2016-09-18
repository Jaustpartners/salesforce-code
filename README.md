# salesforce-code

<b>InvoiceEngine.cls:</b> This class, written using Apex, will auto generate Invoice for a service ticket, based on complex set of business rules.  The rules will take in to account Enittlements the user has, Product Price Lists, Employee RateLists and will apply on Time, Expense and Part Movements performed on work order and any customer orders associated with the Service Ticket. The code is invoked from a button on Service Ticket.

<b>EntitlementUtilities.cls:</b> This class  written using Apex will allow the administrator to generate new entitlements for the customer, with complicated set of rules, by using pre configured  Entitlement Template as its base.

<b>Dispatch_Board.page:</b> Visualforce page written in Jquery and Visualforce is a dispatchboard. The Dispatcher can use drag and drop functionality to assign the Field Service Tasks to Technicians. The drop downs allow the dispatcher to chooose specific service region and date. The dispatcher drags the Field task from bottom applet and drops at a specific date and time on the dispatch board. Written using extensive use of JQuery and Visualforce.

