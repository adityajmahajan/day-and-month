//trigger
trigger OrderTrigger1 on Order (before update) {
    if(Trigger.isBefore){
        if(Trigger.isUpdate){
            List<OrderItem> orderItemList = [SELECT Id, Quantity, Product2.Id, 
            Product2.Inventory__c, Product2.ProductCode, OrderId
            FROM OrderItem
            WHERE orderId = :Trigger.new];

            Map<Id, Boolean> isordervalid = new Map<Id, Boolean>(); 
            Map<Id, String> validation_Errors = new Map<Id, String>(); 
            
            for(Order ord: Trigger.new){
                isordervalid.put(ord.Id, True); 
                validation_Errors.put(ord.Id, '');

            }
            
            for(OrderItem orderIL: orderItemList){ 
                System.debug('in Loop for orderItemList');
                System.debug('orderIL.Quantity : '+orderIL.Quantity);
                System.debug('orderIL.Product2.Inventory__c : '+orderIL.Product2.Inventory__c);
                System.debug('orderIL.Product2Id : '+orderIL.Product2Id);
                System.debug('before strt of if conditions');
                if(orderIL.Quantity > orderIL.Product2.Inventory__c){
                    System.debug('in if for orderIL.Quantity > orderIL.Product2.Inventory__c');
                    System.debug('orderIL.Quantity : '+orderIL.Quantity);
                    System.debug('orderIL.Product2.Inventory__c : '+orderIL.Product2.Inventory__c);
                    isordervalid.put(orderIL.OrderId, False); 
                    validation_Errors.put(orderIL.OrderId,validation_Errors.get(orderIL.Id) + 'Order ' + orderIL.Id + ' failed as inventory is less\n');
                }
                if(orderIL.Product2Id == null || !Pattern.matches('PROD-\\d{4}', orderIL.Product2.ProductCode)){
                    System.debug('in if for Pattern.matches');
                    System.debug('orderIL.Product2Id : '+orderIL.Product2Id);
                    System.debug('orderIL.Product2.ProductCode : '+orderIL.Product2.ProductCode);
                    isordervalid.put(orderIL.OrderId, False); 
                    validation_Errors.put(orderIL.OrderId,validation_Errors.get(orderIL.Id) + 'Order failed ' + orderIL.Id + ' ProductId Does not Match Pattern PROD-0000\n');
                }
                if(orderIL.Quantity > 5){
                    System.debug('in if for orderIL.Quantity < 5');
                    System.debug('orderIL.Quantity : '+orderIL.Quantity);
                    isordervalid.put(orderIL.Id, False); 
                    validation_Errors.put(orderIL.Id,validation_Errors.get(orderIL.Id) + 'Order ' + orderIL.OrderId + 'Quantity should be atleat 1\n');
                }
            }
            System.debug('after for loop for orderItems');

            for(Order order: Trigger.new){
                System.debug('in for loop for order');
                order.IsOrderValid__c = isordervalid.get(order.Id); 
                if(validation_Errors.get(order.id) != null){
                    System.debug('in for for loop for validation_Errors ,order.Id is : '+order.Id);
                    order.Validation_Errors__c = validation_Errors.get(order.id); 
                    feb26Afternoon.futureMethod(order.Id);
                    System.debug('after future method call');

                }
            }
            
            System.debug('This is just before update trigger exits.'+isordervalid); 
            update orderItemList;
        }
    }
}

//@future Method
public with sharing class feb26Afternoon {
    
    @future(callout=true)
    public static void futureMethod(Id Ids){
    try {
        EmailManager.sendMail('adityajmahajan@gmail.com','Test1234','Test1234');
        Order orderId = ([SELECT Validation_Errors__c, Name, IsOrderValid__c, Owner.Email from Order WHERE Id = : Ids LIMIT 1]);
        System.debug('In Send email Method order id is : '+orderId);
        String subject;
        System.debug('before if condition orderid.IsOrderValid__c : '+orderId.IsOrderValid__c);
        EmailManager.sendMail(orderId.Owner.Email,String.valueOf(OrderId.IsOrderValid__c),'Test123567890');
        try{
        if(orderId.IsOrderValid__c){
            System.debug('in if condition orderid.IsOrderValid__c : '+orderId.IsOrderValid__c);
            //orderId.Validation_Errors__c = 'Dear ' + orderId.Owner.Name +'\n';
            orderId.Validation_Errors__c += 'Your order is Valid';
            subject ='Order Validated';
            EmailManager.sendMail(orderId.Owner.Email,subject,orderid.Validation_Errors__c);

        }
        else{
            System.debug('in else if condition orderid.IsOrderValid__c : '+orderId.IsOrderValid__c);
            //orderId.Validation_Errors__c = 'Dear ' + orderId.Owner.Name +'\n';
            orderId.Validation_Errors__c += ' Order Invalid : \n'+ orderId.Validation_Errors__c;
            subject ='Order Invalid';
            EmailManager.sendMail(orderId.Owner.Email,subject,orderid.Validation_Errors__c);
        }
        }
        catch (Exception e){            System.debug('An error occurred: ' + e.getMessage());
    }
        try {
        EmailManager.sendMail('adityajmahajan@gmail.com','Test129999934','Test199999234');
        }
        catch (Exception e) {
            
            System.debug('An error occurred: ' + e.getMessage());
        }
        System.debug('Before Send mail method. Email : '+orderid.Owner.Email);
        System.debug('Before Send mail method. subject : '+subject);
        System.debug('Before Send mail method. orderid.Validation_Errors__c : '+orderid.Validation_Errors__c);
        System.debug('After Send mail method.');
        }
        catch (Exception e) {
            
            System.debug('An error occurred: ' + e.getMessage());
        }
    }
    
}