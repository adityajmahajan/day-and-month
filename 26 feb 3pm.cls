//trigger
trigger OrderTrigger1 on Order (before insert, before update) {
    if(Trigger.isBefore){
        if(Trigger.isUpdate||Trigger.isInsert){
            List<OrderItem> orderItemList = [SELECT Id, Quantity, Product2.Id, 
            Product2.Inventory__c, Product2.ProductCode, OrderId
            FROM OrderItem
            WHERE orderId = :Trigger.new];

            Map<Id, Boolean> isordervalid = new Map<Id, Boolean>(); 
            Map<Id, String> validation_Errors = new Map<Id, String>(); 
            if(isordervalid.size()>=1)
            {
                for(Order ord: Trigger.new){
                    isordervalid.put(ord.Id, True); 
                    validation_Errors.put(ord.Id, '');

                }
                
                for(OrderItem orderIL: orderItemList){ 
                    if(orderIL.Quantity > orderIL.Product2.Inventory__c){
                        isordervalid.put(orderIL.OrderId, False); 
                        validation_Errors.put(orderIL.OrderId,validation_Errors.get(orderIL.Id) + 'Order ' + orderIL.Id + ' failed as inventory is less\n');
                    }
                    if(orderIL.Product2Id == null || !Pattern.matches('PROD-\\d{4}', orderIL.Product2.ProductCode)){
                        isordervalid.put(orderIL.OrderId, False); 
                        validation_Errors.put(orderIL.OrderId,validation_Errors.get(orderIL.Id) + 'Order failed ' + orderIL.Id + ' ProductId Does not Match Pattern PROD-0000\n');
                    }
                    if(orderIL.Quantity > 1){
                        isordervalid.put(orderIL.Id, False); 
                        validation_Errors.put(orderIL.Id,validation_Errors.get(orderIL.Id) + 'Order ' + orderIL.OrderId + 'Quantity should be atleat 1\n');
                    }
                }
                for(Order order: Trigger.new){
                    order.IsOrderValid__c = isordervalid.get(order.Id); 
                    if(validation_Errors.get(order.id) != null){
                        order.Validation_Errors__c = validation_Errors.get(order.id); 
                        feb26Afternoon.futureMethod(order.Id);
                    }
                }
                update orderItemList;
            }
        }
    }
}
//@future Method
public with sharing class feb26Afternoon {
    @future(callout=true)
    public static void futureMethod(Id Ids){
        try {
            List<Order> orders = ([SELECT Id, Validation_Errors__c, Name, IsOrderValid__c, Owner.Email,Owner.Name from Order WHERE Id = : Ids]);
            System.debug(orders);
            String subject;
            String body;
            for(Order ord :orders){
                if(ord.IsOrderValid__c){
                    body = 'Dear '+ord.Owner.Name+', \n';
                    body+= 'Your order is Valid';
                    subject ='Order Validated';
                    EmailManager.sendMail(ord.Owner.Email,subject,body);
                }
                else{
                    body = 'Dear'+ord.Owner.Name+', \n';
                    body+= ' Order Invalid : \n'+ ord.Validation_Errors__c;
                    subject ='Order Invalid';
                    EmailManager.sendMail(ord.Owner.Email, subject ,body);
                }
            }
        }
        catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
        }
    }
}
