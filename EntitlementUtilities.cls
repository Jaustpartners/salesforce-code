public class EntitlementUtilities {
	/*
    public String OldcontractId = '80036000000IbJX';
    public String entitlementTemplateId = '';
    public String assetId = '';
    public String accountId = '001360000039BC1';
    */
    public static void createNewEntitlement(String accountId, 
                                            String contractId, 
                                            String entitlementTemplateId, 
                                            List<String> assetIds )
    {
                                                   
        //if not contract selected, create new contract based on entitlementTemplate,account
        if(contractId == '')
        {
           Contract newContract = createNewContract(accountId,entitlementTemplateId);
           contractId = newContract.Id;
        }
                 
        //Read Entitlement Template Header Info
        Entitlement_Template__c  entT = 
            [SELECT Id,Name__c,Type__c,Price_Book__c,Rate_Book__c,Billable__c
             FROM Entitlement_Template__c 
             WHERE Id  = :entitlementTemplateId];
        
        Entitlement__c et = new Entitlement__c(
            					Contract__c = contractId, 
            					Name = entT.Name__c,
                                Type__c = entT.Type__c,
                                PriceBook__c = entT.Price_Book__c,
                                Ratebook__c = entT.Rate_Book__c,
                                Charge__c = entT.Billable__c
        						);
        insert et;  
        
        String entitlementId = et.Id;
        
		copyEntitlementCoverages(entitlementId,entitlementTemplateId);                                                
        CopyAssets(entitlementId,assetIds);                                 
                                                   
     }
     public static Contract createNewContract(String accountId, String entitlementTemplateId)
    {
        Contract c  = new Contract(AccountId = accountId , Status = 'Draft', StartDate = System.today(),ContractTerm = 12 ); 
        insert c;  
        //system.debug('contract created with id:'+c.Id);
        return c;
    }
    public static void copyEntitlementCoverages(String entitlementId,String entitlementTemplateId)
    {
        List <Entitlement_Service_Coverage_Template__c> entTemplCoverages = 
            [SELECT Id,Task_Type__c,Time_Billable__c,Parts_Billable__c,Expenses_Billable__c,Minimum_Charge__c
             FROM Entitlement_Service_Coverage_Template__c 
             WHERE Entitlement_Template__c  = :entitlementTemplateId ];
        //Loop through list of coverages and copy on to template
        Entitlement_Service_Coverage__c[] entCoverages = new List<Entitlement_Service_Coverage__c>();
        
        for(Entitlement_Service_Coverage_Template__c eTC : entTemplCoverages)
            {
                Entitlement_Service_Coverage__c eC = new Entitlement_Service_Coverage__c
                    (Entitlement__c=entitlementId,
                     Service_Task_Type__c=eTC.Task_Type__c,
                     Time_Billable__c=eTC.Time_Billable__c, 
                     Parts_Billable__c=eTC.Parts_Billable__c, 
                     Expenses_Billable__c=eTC.Expenses_Billable__c, 
                     Minimum_Charge__c=eTC.Minimum_Charge__c);
                
                entCoverages.add(eC);   
            }
		insert entCoverages;        
    
        
        
        
    }
    
    public static void CopyAssets(String entitlementId,List<String> assetIds)
    {
        // Entitlement_Product__c Entitlement__c  Serial__c

        List<Entitlement_Product__c> entProducts = new List<Entitlement_Product__c>();
        for(String assetId : assetIds)
            {
                Entitlement_Product__c eP = new Entitlement_Product__c
                    (Entitlement__c=entitlementId,
                     Serial__c=assetId);
                
                entProducts.add(eP);   
            }
		insert entProducts; 
        
    }
        
  
    
}