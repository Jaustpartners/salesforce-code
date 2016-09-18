# salesforce-code

Dispatch_Board.page  : Visualforce page written in Jquery and Visualforce is dispatchboard. The Dispatcher can use drag and drop functionality to assign the Field Service Tasks to Technicians. The drop downs allow the dispatcher to chooose specific service region and date. The dispatcher drags the Field task from bottom applet and drops at a specific time for the dispatch board. Written using extensive use of JQuery and Visualforce.

Invoice Engine: This class written using Apex will automatically generate Invoice for a service ticket based on complex set of rules.  The rules will take in to account Enittlements the user has, Price List, RateLists and will apply on Time, Expense and Part Movements performed on work order and any customer orders on the Service Ticket. The code is invoked from a button on Service Ticket.

Entitlement Utilities: This class  written using Apex will allow the administrator to generate new entitlements for the customer, with complicated set of rules, by using pre configured  Entitlement Template as its base.
